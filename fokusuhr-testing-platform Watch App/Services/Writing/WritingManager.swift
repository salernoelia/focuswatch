//
//  WritingManager.swift
//  FokusUhr Watch App
//
//  Created by Julian Amacker on 21.05.2024.

import CoreMotion
import Foundation

// MARK: - WritingManager Class
/// Manages accelerometer data collection, processing, and activity detection (writing vs. not writing).
/// It interacts with `WritingMotionManager` to get sensor data and uses either a simple EMA model or a CoreML model
/// to determine the user's current state. It also handles the recording of raw sensor data.
class WritingManager {
  // MARK: - Properties

  /// A weak reference to the `WritingExerciseManager` to prevent retain cycles and allow communication.
  weak var exerciseManager: WritingExerciseManager?

  /// An instance of `WritingMotionManager` to handle real-time accelerometer data buffering.
  private var motionManager = WritingMotionManager()

  /// A `CMSensorRecorder` instance used for background recording of accelerometer data for the entire session.
  private var sensorRecorder = CMSensorRecorder()

  /// A published property indicating the current detected writing state.
  @Published var write: Bool = false

  /// The start date of the sensor recording.
  private var recordingStartDate: Date?

  /// The total duration of the exercise session, used to determine the recording length.
  var totalExerciseTime: Double

  /// A dictionary to store prediction probabilities from the ML model.
  var probabilities: [Int: String] = [:]

  /// A dictionary to hold the results from the EMA (Ecological Momentary Assessment) model.
  var resultEmaModel: [String: Float] = [:]

  /// The current state of the writing detection model, preserving state between updates.
  var currentModelState: ModelState? = nil

  /// A unique prefix for the device ID.
  let deviceID = WatchConfig.shared.uuid.prefix(6)

  /// The current user configuration for the session.
  var currentSetting: Config?

  // MARK: - Initializer

  /// Initializes the `WritingManager`, loading user settings and calculating the total exercise time based on those settings.
  init() {
    let currentSetting =
      UserConfigs.loadConfigFromUserDefaults(forKey: "config_\(deviceID)") ?? Config()
    self.currentSetting = currentSetting
    let reps = Double(currentSetting.repetitions)
    let learn = Double(currentSetting.learn * 60)
    let pause = Double(currentSetting.pause * 60)
    // Calculate total time for Pomodoro-style session by default.
    self.totalExerciseTime = Double(learn * reps + pause * (reps - 1))
  }

  // MARK: - Session Management

  /// Starts the accelerometer updates and background sensor recording.
  /// - Parameters:
  ///   - isPomodoro: A boolean indicating if the session is a Pomodoro session, which affects `totalExerciseTime`.
  ///   - completion: A completion handler that returns the start date of the recording.
  func startWritingManager(isPomodoro: Bool, completion: @escaping (Date?) -> Void) {
    let settingSampleFreq = Double(currentSetting?.modelParams.samplingRateHz ?? 100)
    motionManager.startAccelerometerUpdates(updateInterval: 1 / settingSampleFreq)

    // For non-Pomodoro sessions, set a fixed total exercise time (e.g., 1 hour -> which is the maximum allowed time for backgroun wk session. If longer sessions needed, additional wk extended session logic is needed).
    if !isPomodoro {
      self.totalExerciseTime = 3600  // 60 minutes in seconds
    }

    print("total Excercise Time: \(self.totalExerciseTime)")

    // Start recording on a background thread.
    DispatchQueue.global(qos: .background).async { [weak self] in
      guard let self = self else {
        DispatchQueue.main.async { completion(nil) }
        return
      }

      if CMSensorRecorder.isAccelerometerRecordingAvailable() {
        let duration = self.totalExerciseTime + 2  // Add a small buffer to the duration.
        self.sensorRecorder.recordAccelerometer(forDuration: duration)
        let startDate = Date()
        DispatchQueue.main.async {
          completion(startDate)
        }
      } else {
        DispatchQueue.main.async {
          completion(nil)
        }
      }
    }
  }

  /// Stops the real-time accelerometer updates.
  func stopWritingManager() {
    motionManager.stopAccelerometerUpdates()
    // The CMSensorRecorder stops automatically after its specified duration.
  }

  /// Resets the `thinkCount` in the current model state, effectively resetting the "thinking" timer.
  func resetThinkCount() {
    let defaultModelParams = ModelParams()

    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      if self.currentModelState != nil {
        // Reset think count based on model parameters.
        self.currentModelState?.thinkCount = Int(
          defaultModelParams.samplingRateHz * defaultModelParams.budgetThinkSec)
        self.currentModelState?.status = 1  // Set status to 'thinking'.
        print("Reset thinkCount to \(self.currentModelState?.thinkCount ?? 0) at \(Date())")
      }
    }
  }

  // MARK: - Activity Detection

  /// The main entry point for checking the user's writing status. It dispatches to the appropriate model.
  /// - Parameters:
  ///   - isMLMode: A flag to decide between the ML model and the EMA model. (Note: Deprecated in `WritingExerciseManager`)
  ///   - currentTime: The current time in the session.
  /// - Returns: A tuple containing the probability of writing and the status code.
  func checkIfWriting(isMLMode: Bool, currentTime: Int) -> (Float, Int) {
    // Determine whether to use the EMA model or the ML model.
    let simpleModel = self.currentSetting?.emaModel ?? true

    DispatchQueue.global(qos: .background).async { [weak self] in
      guard let self = self else { return }
      if simpleModel {
        self.processEMAModel()
      } else {
        self.processMLModel(currentTime: currentTime)
      }
    }

    // Return the latest state from the model.
    return (self.currentModelState?.proba ?? 0.0, self.currentModelState?.status ?? 0)
  }

  /// Processes accelerometer data using the simple, rule-based EMA model.
  private func processEMAModel() {
    let settingSampleFreq = Int(currentSetting?.modelParams.samplingRateHz ?? 100)
    let accelerometerDataArray = self.motionManager.dataBuffer.toArray().compactMap { $0 }

    // Limit the input data to the expected size (e.g., 1 second worth of data).
    let limitedDataArray = accelerometerDataArray.prefix(settingSampleFreq)

    let params = self.currentSetting?.modelParams ?? ModelParams()
    let featureDataArray: [[Float]] = limitedDataArray.map { data in
      let x = Float(data.acceleration.x)
      let y = Float(data.acceleration.y)
      let z = Float(data.acceleration.z)
      return [x, y, z]
    }

    // Pass the data to the writing model function to get the new state.
    self.currentModelState = writingModel(
      XYZ: featureDataArray, params: params, initState: self.currentModelState)
    let status = self.currentModelState?.status ?? 0

    // Update the published 'write' state based on the model's output status.
    let currentWriteState = (status == 0)  // Status 0 typically means 'working'.
    DispatchQueue.main.async {
      self.updateWriteState(currentWriteState)
    }

    // Store the processed feature data to a binary file for later analysis.
    self.storeFeatureDataToBinary(featureDataArray: featureDataArray)
  }

  /// Processes accelerometer data using the pre-trained CoreML model.
  private func processMLModel(currentTime: Int) {
    let accelerometerDataArray = self.motionManager.dataBuffer.toArray().compactMap { $0 }
    let predictionResult = self.predictWriting(from: accelerometerDataArray)
    let threshold = 0.25
    var currentWriteState = false

    // Determine writing state based on the prediction label and probability.
    if predictionResult.classLabel == 2 {  // Label 2 is 'writing'.
      currentWriteState = true
    } else if predictionResult.classLabel == 1,
      let probabilityString = predictionResult.probabilities[2],
      let probabilityValue = Double(probabilityString), probabilityValue > threshold
    {
      // If the model is unsure (label 1), but probability for writing (class 2) is high.
      currentWriteState = true
    }

    // Override at the beginning of the session to assume writing.
    let bufferSize = self.motionManager.bufferSize
    if currentTime < (bufferSize / 60) {
      currentWriteState = true
    }

    // Update the UI and internal state on the main thread.
    DispatchQueue.main.async {
      self.probabilities = predictionResult.probabilities
      self.updateWriteState(currentWriteState)
    }
  }

  /// Calls the CoreML model predictor.
  /// - Parameter buffer: An array of `CMAccelerometerData`.
  /// - Returns: A tuple containing the predicted class label and a dictionary of probabilities.
  private func predictWriting(from buffer: [CMAccelerometerData]) -> (
    classLabel: Int64?, probabilities: [Int: String]
  ) {
    let predictor = ActivityPredictor()
    return predictor.predictActivity(from: buffer)
  }

  /// Updates the `write` property only if the new state is different from the current state.
  private func updateWriteState(_ currentWriteState: Bool) {
    if self.write != currentWriteState {
      self.write = currentWriteState
    }
  }

  // MARK: - Binary Data Storage

  /// Saves the raw feature data (accelerometer XYZ) to a binary file.
  /// This is used for offline analysis and model retraining.
  private func storeFeatureDataToBinary(featureDataArray: [[Float]]) {
    var binaryData = Data()

    // Encode each [x, y, z] vector into a binary format.
    featureDataArray.forEach { feature in
      // Scale and convert to Int16 to save space.
      let x = Int16(feature[0] * 4096)
      let y = Int16(feature[1] * 4096)
      let z = Int16(feature[2] * 4096)
      let record = AccelerometerRecord(deltaTimestamp: 0, x: x, y: y, z: z)
      binaryData.append(self.encodeRecord(record))
    }

    // Use the session filename to create a corresponding .bin filename.
    guard let sessionFilename = self.exerciseManager?.sessionFilename else {
      print("Session filename is not available")
      return
    }
    let binaryFilename = sessionFilename.replacingOccurrences(of: ".json", with: ".bin")
    let binaryFileURL = self.getDocumentsDirectory().appendingPathComponent(binaryFilename)

    // Write the binary data to the file.
    do {
      try binaryData.write(to: binaryFileURL)
    } catch {
      print("Failed to write binary data: \(error)")
    }
  }

  /// Encodes a single `AccelerometerRecord` into raw `Data`.
  private func encodeRecord(_ record: AccelerometerRecord) -> Data {
    var data = Data()
    withUnsafeBytes(of: record.deltaTimestamp) { data.append(contentsOf: $0) }
    withUnsafeBytes(of: record.x) { data.append(contentsOf: $0) }
    withUnsafeBytes(of: record.y) { data.append(contentsOf: $0) }
    withUnsafeBytes(of: record.z) { data.append(contentsOf: $0) }
    return data
  }

  /// A helper function to get the app's documents directory URL.
  private func getDocumentsDirectory() -> URL {
    return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
  }
}

// MARK: - CMSensorDataList Extension
/// Makes `CMSensorDataList` conform to the `Sequence` protocol, allowing it to be iterated over easily.
extension CMSensorDataList: @retroactive Sequence {
  public func makeIterator() -> NSFastEnumerationIterator {
    return NSFastEnumerationIterator(self)
  }
}
