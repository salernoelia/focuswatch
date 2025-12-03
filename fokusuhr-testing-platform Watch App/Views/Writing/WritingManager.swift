import CoreMotion
import Foundation

class WritingManager {
  weak var exerciseManager: WritingExerciseManager?
  private var motionManager = WritingMotionManager()
  private var sensorRecorder = CMSensorRecorder()

  @Published var write: Bool = false
  private var recordingStartDate: Date?
  var totalExerciseTime: Double

  var probabilities: [Int: String] = [:]
  var resultEmaModel: [String: Float] = [:]
  var currentModelState: ModelState? = nil
  private var lastProcessedIndex: Int = 0

  let deviceID = WatchConfig.shared.uuid.prefix(6)
  var currentSetting: Config?
  var sharedConfiguration = WatchConnector.loadAppConfigurations().writing

  init() {
    let currentSetting =
      UserConfigs.loadConfigFromUserDefaults(forKey: "config_\(deviceID)") ?? Config()
    self.currentSetting = currentSetting

    let reps = Double(currentSetting.repetitions)
    let learn = Double(currentSetting.learn * 60)
    let pause = Double(currentSetting.pause * 60)
    self.totalExerciseTime = Double(learn * reps + pause * (reps - 1))

    setupConfigurationObserver()
  }

  private func setupConfigurationObserver() {
    NotificationCenter.default.addObserver(
      forName: .appConfigurationsUpdated,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      guard let self = self,
        let configurations = notification.object as? AppConfigurations
      else { return }

      self.sharedConfiguration = configurations.writing
      self.applySharedConfiguration()

      #if DEBUG
        print("✅ Writing: Applied configuration from iOS")
      #endif
    }
  }

  func applySharedConfiguration() {
    guard let currentSetting = currentSetting else { return }

    var updatedSetting = currentSetting
    updatedSetting.learn = sharedConfiguration.workMinutes
    updatedSetting.think = sharedConfiguration.thinkMinutes
    updatedSetting.pause = sharedConfiguration.pauseMinutes
    updatedSetting.repetitions = sharedConfiguration.repetitions

    self.currentSetting = updatedSetting
    updateTotalExerciseTime()
  }

  private func updateTotalExerciseTime() {
    guard let currentSetting = currentSetting else { return }
    let reps = Double(currentSetting.repetitions)
    let learn = Double(currentSetting.learn * 60)
    let pause = Double(currentSetting.pause * 60)
    self.totalExerciseTime = Double(learn * reps + pause * (reps - 1))
  }

  func startWritingManager(isPomodoro: Bool, completion: @escaping (Date?) -> Void) {
    applySharedConfiguration()
    let settingSampleFreq = Double(currentSetting?.modelParams.samplingRateHz ?? 25)
    motionManager.startAccelerometerUpdates(updateInterval: 1 / settingSampleFreq)

    currentModelState = nil
    lastProcessedIndex = 0

    if !isPomodoro {
      self.totalExerciseTime = 3600
    }

    DispatchQueue.global(qos: .background).async { [weak self] in
      guard let self = self else {
        DispatchQueue.main.async { completion(nil) }
        return
      }

      if CMSensorRecorder.isAccelerometerRecordingAvailable() {
        let duration = self.totalExerciseTime + 2
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

  func stopWritingManager() {
    motionManager.stopAccelerometerUpdates()
    currentModelState = nil
    lastProcessedIndex = 0
  }

  func resetThinkCount() {
    let defaultModelParams = currentSetting?.modelParams ?? ModelParams()
    let thinkCountBudget = Int(
      defaultModelParams.budgetThinkSec * defaultModelParams.samplingRateHz)

    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      if self.currentModelState != nil {
        self.currentModelState?.thinkCount = thinkCountBudget
        self.currentModelState?.status = 0
        self.currentModelState?.stillnessCount = 0
        self.currentModelState?.motionCount = 0
      }
    }
  }

  func checkIfWriting(currentTime: Int) -> (Float, Int) {
    let useMLModel = !(self.currentSetting?.emaModel ?? true)

    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self = self else { return }
      if useMLModel {
        self.processMLModel(currentTime: currentTime)
      } else {
        self.processEMAModel()
      }
    }

    return (self.currentModelState?.proba ?? 0.5, self.currentModelState?.status ?? 0)
  }

  private func processEMAModel() {
    let accelerometerDataArray = self.motionManager.dataBuffer.toArray().compactMap { $0 }

    guard !accelerometerDataArray.isEmpty else {
      return
    }

    let params = self.currentSetting?.modelParams ?? ModelParams()
    let featureDataArray: [[Float]] = accelerometerDataArray.map { data in
      let x = Float(data.acceleration.x)
      let y = Float(data.acceleration.y)
      let z = Float(data.acceleration.z)
      return [x, y, z]
    }

    self.currentModelState = writingModel(
      XYZ: featureDataArray, params: params, initState: self.currentModelState)
    let status = self.currentModelState?.status ?? 0

    let currentWriteState = (status == 0)
    DispatchQueue.main.async {
      self.updateWriteState(currentWriteState)
    }

    self.storeFeatureDataToBinary(featureDataArray: featureDataArray)
  }

  private func processMLModel(currentTime: Int) {
    let accelerometerDataArray = self.motionManager.dataBuffer.toArray().compactMap { $0 }
    let predictionResult = self.predictWriting(from: accelerometerDataArray)
    let threshold = 0.25
    var isWriting = false
    var status = 2

    if predictionResult.classLabel == 2 {
      isWriting = true
      status = 0
    } else if predictionResult.classLabel == 1,
      let probabilityString = predictionResult.probabilities[2],
      let probabilityValue = Double(probabilityString), probabilityValue > threshold
    {
      isWriting = true
      status = 0
    } else if predictionResult.classLabel == 1 {
      status = 1
    }

    let bufferSize = self.motionManager.bufferSize
    if currentTime < (bufferSize / 60) {
      isWriting = true
      status = 0
    }

    let proba = Float(predictionResult.probabilities[2].flatMap { Double($0) } ?? 0.0)

    if self.currentModelState == nil {
      self.currentModelState = ModelState(
        index: 0, g: 1.0, xf: 0, yf: 0, zf: 0, vf2: 0, vf2t: 0, vf2max: 0, vf2min: 0,
        xs: 0, ys: 0, zs: 0, vs2: 0, xfcross: 0, yfcross: 0, zfcross: 0,
        vf2maxcross: 0, vf2mincross: 0, vs2cross: 0, periodSec: 0, periodCount: 0,
        exponent: 0, proba: proba, probaSlow: 0, probaFast: 0, probaAvg: 0,
        thinkCount: 0, status: status,
        motionLevel: 0, motionAvg: 0, stillnessCount: 0, motionCount: 0
      )
    } else {
      self.currentModelState?.proba = proba
      self.currentModelState?.status = status
    }

    DispatchQueue.main.async {
      self.probabilities = predictionResult.probabilities
      self.updateWriteState(isWriting)
    }
  }

  private func predictWriting(from buffer: [CMAccelerometerData]) -> (
    classLabel: Int64?, probabilities: [Int: String]
  ) {
    let predictor = ActivityPredictor()
    return predictor.predictActivity(from: buffer)
  }

  private func updateWriteState(_ currentWriteState: Bool) {
    if self.write != currentWriteState {
      self.write = currentWriteState
    }
  }

  private func storeFeatureDataToBinary(featureDataArray: [[Float]]) {
    var binaryData = Data()

    featureDataArray.forEach { feature in
      let x = Int16(feature[0] * 4096)
      let y = Int16(feature[1] * 4096)
      let z = Int16(feature[2] * 4096)
      let record = AccelerometerRecord(deltaTimestamp: 0, x: x, y: y, z: z)
      binaryData.append(self.encodeRecord(record))
    }

    guard let sessionFilename = self.exerciseManager?.sessionFilename else {
      return
    }
    let binaryFilename = sessionFilename.replacingOccurrences(of: ".json", with: ".bin")
    let binaryFileURL = self.getDocumentsDirectory().appendingPathComponent(binaryFilename)

    do {
      try binaryData.write(to: binaryFileURL)
    } catch {
      print("Failed to write binary data: \(error)")
    }
  }

  private func encodeRecord(_ record: AccelerometerRecord) -> Data {
    var data = Data()
    withUnsafeBytes(of: record.deltaTimestamp) { data.append(contentsOf: $0) }
    withUnsafeBytes(of: record.x) { data.append(contentsOf: $0) }
    withUnsafeBytes(of: record.y) { data.append(contentsOf: $0) }
    withUnsafeBytes(of: record.z) { data.append(contentsOf: $0) }
    return data
  }

  private func getDocumentsDirectory() -> URL {
    return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
  }
}

extension CMSensorDataList: @retroactive Sequence {
  public func makeIterator() -> NSFastEnumerationIterator {
    return NSFastEnumerationIterator(self)
  }
}
