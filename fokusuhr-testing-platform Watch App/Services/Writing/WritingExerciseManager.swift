//  WritingExerciseManager.swift
//  FokusUhr Watch App
//
//  Created by Julian Amacker on 25.01.2024.

import Combine
import CoreLocation
import CoreMotion
import Foundation
import SwiftUI
import WidgetKit

// MARK: - WritingExerciseManager Class
/// Manages the state, timers, and data logging for an exercise session.
/// This class handles both Pomodoro and non-Pomodoro style sessions,
/// tracking user activity (working, thinking, disrupted) and providing haptic feedback.
/// TODO: RENAME
class WritingExerciseManager: NSObject, ObservableObject {
  // MARK: - Published Properties

  /// The current time remaining in the active timer (exercise or pause), published for UI updates.
  @Published var currentTime: Int = 0

  /// The current state of the exercise session (e.g., .working, .pausing), published for UI updates.
  /// A didSet observer logs every state change.
  @Published var exerciseState: ExerciseState = .ready {
    didSet { logStateChange() }
  }

  /// An optional timer for tracking "thinking" periods.
  @Published var thinkTimer: WritingTimeManager?

  /// The current time remaining in a pause period, published for UI updates.
  @Published var currentPauseTime: Int = 0

  /// A flag to determine if the machine learning model is used for activity detection. Deprecated in version 2.0.
  @Published var isMLMode: Bool = true  // deprecated 2.0

  /// The probability score from the activity prediction model.
  @Published var proba: Float = 0.0

  /// A dictionary holding results from the EMA (Exponential moving average) model.
  @Published var resultEmaModel: [String: Float] = [:]

  /// A boolean flag to indicate if the session is a Pomodoro session.
  @Published var pomodoro: Bool = true

  /// A flag to enable or disable positive haptic feedback.
  @Published var positive_feedback: Bool = false

  /// A flag to control the presentation of the main run view.
  @Published var showRunView: Bool = false

  // MARK: - Timers

  /// An optional timer for managing pause durations between exercise repetitions.
  var pauseTimer: WritingTimeManager?

  /// An optional timer for managing the duration of the main exercise/work period.
  var exerciseTimer: WritingTimeManager?

  /// A private timer used to periodically monitor the user's exercise state.
  private var monitoringTimer: Timer?

  /// A session to keep the app running in the background on watchOS.
  private var extendedRuntimeSession: WKExtendedRuntimeSession?

  // MARK: - Data Management and Configuration

  /// A unique prefix derived from the device's UUID for identification.
  let deviceUUIDPrefix = WatchConfig.shared.uuid.prefix(6)

  /// A computed property to access the current user-defined settings.
  var currentSetting: Config {
    UserConfigs.shared.configs
  }

  /// The start date and time of the data recording for the session.
  var recordStartDate: Date?

  /// The end date and time of the data recording for the session.
  var recordEndDate: Date?

  // MARK: - Haptic Feedback

  /// Lazily initialized manager for handling all haptic feedback.
  lazy var hapticManager: WritingHapticFeedbackManager = {
    return WritingHapticFeedbackManager(WritingExerciseManager: self)
  }()

  // MARK: - Session Data

  /// The filename for the current session's JSON data.
  @Published var sessionFilename: String?

  /// A dictionary to hold all data related to the current session before serialization.
  var sessionData: [String: Any] = [:]

  // MARK: - State Logging

  /// An array to store the history of all state changes during the session.
  var stateHistory: [StateHistoryEntry] = []

  /// An array to store the history of EMA model results (probability and status).
  var emaResHistory: [EmaResHistoryEntry] = []

  /// An array to store the history of working states.
  var workingHistory: [StateHistoryEntry] = []

  // MARK: - Miscellaneous

  /// A set to store Combine framework cancellables, managing subscription lifetimes.
  private var cancellables: Set<AnyCancellable> = []

  /// The number of exercise repetitions remaining in the current routine.
  var repetitionsRemaining: Int = 0

  // MARK: - Location

  /// A shared instance of the location manager to fetch the user's location.
  let writingLocationManager = WritingLocationManager.shared

  /// Lazily initialized manager for writing sensor data to files.
  lazy var writingManager: WritingManager = {
    let manager = WritingManager()
    manager.exerciseManager = self
    return manager
  }()

  // MARK: - Initializer

  /// Initializes the WritingExerciseManager and sets up initial values for the widget.
  override init() {
    super.init()
    storeWidgetValue()
  }

  // MARK: - Extended Runtime Session

  /// Initializes and starts a `WKExtendedRuntimeSession` to allow the app to run in the background.
  func initExtendedSession() {
    print("feedback enabled: \(UserConfigs.shared.configs.feedbackEnabled)")
    guard extendedRuntimeSession == nil else { return }
    extendedRuntimeSession = WKExtendedRuntimeSession()
    extendedRuntimeSession?.delegate = self
    extendedRuntimeSession?.start()
  }

  // MARK: - Pomodoro & Non-Pomodoro Session Flow

  /// Starts the main exercise routine.
  /// This method is the entry point for both Pomodoro and non-Pomodoro sessions.
  func startRoutine() {
    print("Starting routine. Repetitions: \(currentSetting.repetitions)")
    recordStartDate = nil
    repetitionsRemaining = currentSetting.repetitions
    // Sets up the data writer and timers, then starts the first repetition.
    setupWritingManagerAndTimer { [weak self] in
      guard let self = self else { return }
      self.createAndUploadSessionJSON()
      self.startNextRepetition()
    }
  }

  /// Starts the next work/exercise repetition.
  /// If no repetitions are left, the routine is considered complete.
  private func startNextRepetition() {
    guard repetitionsRemaining > 0 else {
      print("Routine completed")
      return
    }
    repetitionsRemaining -= 1

    // The exercise timer duration depends on the mode.
    // **Pomodoro Mode**: Uses the user-defined 'learn' duration.
    // **Non-Pomodoro Mode**: Uses a fixed duration (e.g., 60 minutes) for each cycle.
    self.exerciseTimer = WritingTimeManager(
      time: self.pomodoro ? self.currentSetting.learn : 60, countDown: true)
    self.exerciseTimer?.startTimer()

    // Subscribes to the timer's currentTime publisher to receive updates.
    exerciseTimer?.$currentTime
      .receive(on: DispatchQueue.main)
      .sink(receiveValue: { [weak self] currentTime in
        self?.handleExerciseTimerUpdate(currentTime)
      })
      .store(in: &self.cancellables)

    // Play a starting haptic feedback.
    self.hapticManager.playHaptic(type: .start, repeatCount: 4, delayBetween: 0.5)
  }

  /// Handles updates from the `exerciseTimer`.
  /// This method is called every second during a work interval.
  private func handleExerciseTimerUpdate(_ currentTime: Int) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.currentTime = currentTime
      print("Remaining session time: \(self.currentTime)")

      // **Pomodoro Mode**: When the timer reaches zero, the repetition ends.
      if currentTime <= 0 {
        if self.repetitionsRemaining > 0 {
          self.endRepetition()
          self.startPause()  // Start a pause if more reps are left.
        } else {
          self.stopExercise {}  // End the whole session if no reps are left.
        }
      } else {
        // **Non-Pomodoro Mode**: The session stops when the total accumulated work time reaches the goal.
        if !self.pomodoro, Double(self.totalWorkTime()) >= Double(self.currentSetting.learn) * 60 {
          self.stopExercise {}
        } else {
          self.storeWidgetValue()
          self.monitorExercise()  // Continue monitoring user activity.
        }
      }
    }
  }

  /// Sets up the `WritingManager` and starts the initial timer.
  /// The completion handler is called after the setup is complete.
  func setupWritingManagerAndTimer(completion: @escaping () -> Void) {
    // The write manager is started differently based on the mode.
    writingManager.startWritingManager(isPomodoro: self.pomodoro) { [weak self] startDate in
      guard let self = self, let startDate = startDate else { return }
      DispatchQueue.main.async {
        if self.recordStartDate == nil {
          self.recordStartDate = startDate
          print("Stored recording start date: \(String(describing: self.recordStartDate))")
          UserDefaults.standard.set(startDate, forKey: "accelStartDate")
        }
        completion()
      }
    }
  }

  // MARK: - Activity Monitoring

  /// Monitors the user's activity by checking if they are writing/working.
  /// This method is central to the app's state logic during a work interval.
  private func monitorExercise() {
    // Check the user's current writing status from the WritingManager.
    let (proba, status) = writingManager.checkIfWriting(
      isMLMode: isMLMode, currentTime: currentTime)
    let posFeedbackInterval = currentSetting.posFBIntveral
    DispatchQueue.main.async {
      self.proba = proba
    }

    // Provide positive feedback if conditions are met (working, feedback enabled, etc.).
    if (status == 0 || status == 3) && positive_feedback && currentTime % posFeedbackInterval == 0
      && checkPosFeedback()
    {
      hapticManager.playHaptic(type: .success)
    }

    // Update the exercise state based on the activity status.
    switch status {
    case 0:
      /// User is working.
      if exerciseState != .working {
        startWorking()
      }
    case 1:
      /// User is thinking.
      if exerciseState != .thinking {
        startThinking()
      }
    case 2:
      /// User is disrupted.
      if exerciseState == .pausing {
        startThinking()
      }
      if exerciseState != .disrupted {
        startDisrupt()
      } else {
        // If already disrupted, ensure negative feedback is active.
        if !positive_feedback && (hapticManager.isHapticFeedbackActive == false) {
          hapticManager.startHapticFeedback(interval: TimeInterval(currentSetting.negFBInterval))
          print("Restarted haptic feedback in monitorExercise() at \(Date())")
        }
      }
    case 3:
      /// User is returning to work after a disruption.
      if exerciseState != .backToWork { hapticManager.stopHapticFeedback() }
    default:  // Default to working state.
      if exerciseState != .working {
        startWorking()
      }
    }

    // Log the result of the monitoring check.
    emaResHistory.append(EmaResHistoryEntry(timestamp: Date(), proba: proba, status: status))
  }

  // MARK: - Exercise State Setters

  /// Sets the state to `.working` and stops any ongoing haptic feedback.
  private func startWorking() {
    changeState(to: .working)
    hapticManager.stopHapticFeedback()
  }

  /// Sets the state to `.thinking`.
  private func startThinking() {
    changeState(to: .thinking)
  }

  /// Sets the state to `.disrupted` and starts negative haptic feedback if enabled.
  private func startDisrupt() {
    changeState(to: .disrupted)

    if !positive_feedback {
      hapticManager.startHapticFeedback(interval: TimeInterval(currentSetting.negFBInterval))
      print("Restarted haptic feedback in monitorExercise() at \(Date())")
    }
  }

  /// Starts a pause period between work repetitions.
  /// This is specific to **Pomodoro Mode**.
  private func startPause() {
    pauseTimer = WritingTimeManager(time: currentSetting.pause, countDown: true)
    pauseTimer?.startTimer()
    changeState(to: .pausing)

    writingManager.resetThinkCount()

    // Play a notification haptic.
    hapticManager.playHaptic(type: .notification, repeatCount: 2, delayBetween: 0.8)

    // Subscribe to pause timer updates.
    pauseTimer?.$currentTime
      .receive(on: DispatchQueue.main)
      .sink { [weak self] currentTime in
        guard let self = self else { return }
        self.currentPauseTime = currentTime
        print("pause time: \(self.currentPauseTime)")
        if currentTime <= 0 {
          // When pause is over, start the next repetition.
          print("starting next rep")
          self.pauseTimer?.stopTimer()
          self.pauseTimer = nil
          self.startNextRepetition()
        }
      }
      .store(in: &cancellables)
  }

  // MARK: - Session Cleanup

  /// Ends the current repetition by cleaning up timers.
  private func endRepetition() {
    hapticManager.stopHapticFeedback()
    exerciseTimer?.stopTimer()
    exerciseTimer = nil
    thinkTimer?.stopTimer()
    thinkTimer = nil
    monitoringTimer?.invalidate()
    monitoringTimer = nil
  }

  /// Stops the entire exercise session, saves all data, and cleans up.
  func stopExercise(completion: @escaping () -> Void) {
    hapticManager.playHaptic(type: .stop)

    let dispatchGroup = DispatchGroup()

    // Stop all timers and set state to ended.
    stopTimers()
    changeState(to: .ended) {
      self.hapticManager.stopHapticFeedback()
      self.recordEndDate = Date()
      print("Stored recording end date: \(String(describing: self.recordEndDate))")
    }

    // Save final data using a DispatchGroup to manage asynchronous tasks.
    dispatchGroup.enter()
    storeWidgetValue()
    dispatchGroup.leave()

    dispatchGroup.enter()
    storeEndDate(recordEndDate: recordEndDate ?? Date()) {
      print("storeEndDate completed.")
      dispatchGroup.leave()
    }

    dispatchGroup.enter()
    storeSessionEndJson {
      print("storeSessionEndJson completed.")
      dispatchGroup.leave()
    }

    // After all saving tasks are done, upload the data and reset.
    dispatchGroup.notify(queue: .main) {
      print("All tasks completed, waiting 3 seconds before uploading data to DB.")
      DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
        self.uploadExDataToDB {
          self.resetExercise()
          completion()
        }
      }
    }
  }

  /// Stops all running timers.
  private func stopTimers() {
    monitoringTimer?.invalidate()
    monitoringTimer = nil
    exerciseTimer?.stopTimer()
    exerciseTimer = nil
    thinkTimer?.stopTimer()
    thinkTimer = nil
  }

  /// Resets the manager to its initial state, ready for a new session.
  func resetExercise() {
    changeState(to: .ready)
    writingManager.resetThinkCount()
    stateHistory = []
    workingHistory = []
    emaResHistory = []
    showRunView = false
    extendedRuntimeSession?.invalidate()
  }

  // MARK: - Data Storage and Upload

  /// Stores the end date of the recording in UserDefaults.
  func storeEndDate(recordEndDate: Date, completion: @escaping () -> Void) {
    DispatchQueue.main.async {
      UserDefaults.standard.set(recordEndDate, forKey: "accelEndDate")
      completion()
    }
  }

  /// Initiates the upload of all collected exercise data to the database.
  func uploadExDataToDB(completion: @escaping () -> Void) {
    let manager = DataStorageManager()
    manager.uploadToDB { _ in
      completion()
    }
  }

  /// Updates the value for the home screen widget.
  func storeWidgetValue() {
    DispatchQueue.main.async {
      guard let sharedDefaults = UserDefaults(suiteName: "group.net.com.fokusuhr") else {
        print("Error: Unable to access shared UserDefaults.")
        return
      }
      let totalTime = Double(self.currentSetting.learn * 60)
      let percentage = totalTime > 0 ? Double(self.currentTime) / totalTime : 0
      let endDate = Date().addingTimeInterval(Double(self.currentTime))
      WatchConfig.shared.storeDeviceIDInUserDefaults()
      sharedDefaults.set(percentage, forKey: "remainingTimePercentage")
      sharedDefaults.set(self.exerciseState.rawValue, forKey: "widgetState")
      sharedDefaults.set(endDate, forKey: "endDate")
    }
  }

  /// Creates the initial JSON file for the session with configuration and metadata.
  private func createAndUploadSessionJSON() {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
    dateFormatter.timeZone = TimeZone(identifier: "Europe/Zurich")

    let recordStartDate = self.recordStartDate ?? Date()
    let deviceID = String(self.deviceUUIDPrefix)

    let dateString = dateFormatter.string(from: recordStartDate)
    let filename = "\(deviceID)_\(dateString).json"
    self.sessionFilename = filename
    let currentSetting = self.currentSetting

    print("Creating JSON file for session \(self.sessionFilename ?? "Unknown")")

    var settingsJSON: [String: Any]
    if let dict = try? currentSetting.toDictionary() {
      settingsJSON = dict
    } else {
      print("Failed to convert settings to dictionary.")
      settingsJSON = [:]
    }

    // The projected end date differs by mode.
    var projectEndDateInSeconds = self.currentSetting.learn * 60
    // **Non-Pomodoro Mode**: Projected end is based on total duration (e.g., 1 hour).
    if !self.pomodoro {
      projectEndDateInSeconds = 3600  // 1 hour
    }
    let projectedEndDate = recordStartDate.addingTimeInterval(TimeInterval(projectEndDateInSeconds))
    let projectedEndDateString = dateFormatter.string(from: projectedEndDate)

    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    let dataStorageManager = DataStorageManager()

    // Request location to include in session data.
    writingLocationManager.requestLocation { [weak self] result in
      guard let self = self else { return }
      var location: Any = "N/A"
      switch result {
      case .success(let locationDict):
        print("Location fetched: \(locationDict)")
        location = locationDict
      case .failure(let error):
        print("Failed to fetch location: \(error.localizedDescription)")
      }

      // Prepare combined session data.
      self.sessionData = [
        "ID": deviceID,
        "date": dateString,
        "config": settingsJSON,
        "location": location,
        "AppVersion": version,
        "SessionEndDate": projectedEndDateString,
      ]

      print("Session Data: \(self.sessionData)")
      // Create and upload the initial session JSON.
      dataStorageManager.createSessionJSON(data: self.sessionData, filename: filename) { _ in
        do {
          let jsonData = try JSONSerialization.data(withJSONObject: self.sessionData, options: [])

          dataStorageManager.uploadDataToWebhook(jsonData: jsonData) { result in
            switch result {
            case .success:
              print("Session JSON uploaded to Elastic.")
            case .failure(let error):
              print(self.sessionData)
              print("Failed to upload session JSON: \(error.localizedDescription)")
            }
          }
        } catch {
          print("Failed to serialize sessionData to JSON: \(error.localizedDescription)")
        }
      }
    }
  }

  /// Updates the session JSON file with the final results and end date.
  func storeSessionEndJson(completion: @escaping () -> Void) {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
    dateFormatter.timeZone = TimeZone(identifier: "Europe/Zurich")
    let endDateString = dateFormatter.string(from: self.recordEndDate ?? Date())

    // Add final data to the session dictionary.
    self.sessionData["modelResult"] = self.emaResHistory.map { $0.toDictionary() }
    self.sessionData["SessionEndDate"] = endDateString

    guard let filename = self.sessionFilename else {
      print("Session filename is missing.")
      completion()
      return
    }

    let dataStorageManager = DataStorageManager()

    // Update the JSON file on disk.
    dataStorageManager.updateSessionJSON(data: self.sessionData, filename: filename) { result in
      switch result {
      case .success:
        dataStorageManager.addToUploads(filename: filename)
        print("Session JSON updated successfully.")
      case .failure(let error):
        print("Failed to update session JSON: \(error.localizedDescription)")
      }
      completion()
    }
  }
}

// MARK: - WKExtendedRuntimeSessionDelegate
extension WritingExerciseManager: WKExtendedRuntimeSessionDelegate {
  /// Called when the extended runtime session has successfully started.
  func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
    startRoutine()
  }

  /// Called when the extended runtime session is about to expire.
  func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
    // Cleanly stop the exercise when the session is about to end.
    DispatchQueue.main.async {
      self.stopExercise {}
    }
  }

  /// Called when the extended runtime session becomes invalid for some reason.
  func extendedRuntimeSession(
    _ extendedRuntimeSession: WKExtendedRuntimeSession,
    didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?
  ) {
    self.extendedRuntimeSession = nil
    logToFile("Extended Runtime Session Invalidated. Reason: \(reason) \(Date())")

    switch reason {
    case .error, .expired:
      // Attempt to start a new session if it expired or an error occurred.
      startNewExtendedRuntimeSession()
    case .resignedFrontmost:
      logToFile("Session invalidated due to resigned frontmost. Not starting a new session.")
    case .suppressedBySystem:
      logToFile("Session suppressed by system. Will not start a new session now.")
    case .sessionInProgress:
      logToFile("Session invalidated with reason 'sessionInProgress'. This should not occur here.")
    case .none:
      logToFile("Session ended normally.")
    @unknown default:
      logToFile("Session invalidated with unknown reason.")
    }
  }

  /// Attempts to start a new `WKExtendedRuntimeSession`.
  func startNewExtendedRuntimeSession() {
    extendedRuntimeSession = WKExtendedRuntimeSession()
    extendedRuntimeSession?.delegate = self
    extendedRuntimeSession?.start()
    if let state = extendedRuntimeSession?.state, state == .invalid {
      logToFile("Failed to start new Extended Runtime Session. State: \(state) \(Date())")
    } else {
      logToFile("Started new Extended Runtime Session \(Date())")
    }
  }

  /// A helper function to log messages to a local file for debugging.
  private func logToFile(_ message: String) {
    DispatchQueue.global(qos: .background).async {
      let fileManager = FileManager.default
      guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
      else { return }
      let logFileURL = documentsPath.appendingPathComponent("CPULog.txt")

      do {
        if fileManager.fileExists(atPath: logFileURL.path) {
          let fileHandle = try FileHandle(forWritingTo: logFileURL)
          defer {
            try? fileHandle.close()
          }
          fileHandle.seekToEndOfFile()
          if let data = (message + "\n").data(using: .utf8) {
            fileHandle.write(data)
          }
        } else {
          if let data = (message + "\n").data(using: .utf8) {
            try data.write(to: logFileURL, options: .atomic)
          }
        }
      } catch {
        print("Failed to log to file: \(error.localizedDescription)")
      }
    }
  }
}

// MARK: - State Management and History
extension WritingExerciseManager {
  /// Changes the current exercise state and logs the change.
  func changeState(to newState: ExerciseState, completion: (() -> Void)? = nil) {
    exerciseState = newState
    completion?()
  }

  /// Logs a state change to the history, updates the session JSON, and uploads the live state.
  func logStateChange(hapticFeedbackType: ExerciseState? = nil) {
    let dataStorageManager = DataStorageManager()
    let deviceID = String(self.deviceUUIDPrefix)
    let stateEntry = hapticFeedbackType ?? exerciseState
    let entry = StateHistoryEntry(timestamp: Date(), state: stateEntry)

    self.stateHistory.append(entry)
    self.sessionData["stateHistory"] = self.stateHistory.map { $0.toDictionary() }

    // Update the main session JSON file.
    if let filename = self.sessionFilename {
      dataStorageManager.updateSessionJSON(data: self.sessionData, filename: filename) { _ in }
    }

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
    dateFormatter.timeZone = TimeZone(identifier: "Europe/Zurich")
    let dateString = dateFormatter.string(from: self.recordStartDate ?? Date())

    // Upload the latest state change for live tracking.
    dataStorageManager.uploadLive(
      stateEntries: [entry], deviceID: String(deviceID), dateString: dateString
    ) { _ in }
  }

  /// Checks if positive feedback should be given by ensuring no recent disruptions occurred.
  func checkPosFeedback() -> Bool {
    let currentTime = Date()
    let timeInterval: TimeInterval = TimeInterval(self.currentSetting.posFBIntveral)

    // Look back in history for recent disruptions.
    for entry in stateHistory.reversed() {
      if currentTime.timeIntervalSince(entry.timestamp) <= timeInterval, entry.state == .disrupted {
        return false  // Found a recent disruption, so no positive feedback.
      } else if entry.state != .disrupted {
        return true  // Found a non-disrupted state first, so it's okay.
      }
    }
    return true  // No disruptions found in recent history.
  }

  /// Calculates the total accumulated work time (time spent in `.working` or `.thinking` states).
  /// This is primarily used for the **Non-Pomodoro Mode** to determine when the session goal is met.
  func totalWorkTime() -> TimeInterval {
    var totalWorkTime: TimeInterval = 0
    var lastTimestamp: Date?
    var lastState: ExerciseState?

    for entry in stateHistory {
      if let lastTimestamp = lastTimestamp, let lastState = lastState {
        let timeSpent = entry.timestamp.timeIntervalSince(lastTimestamp)
        if lastState == .working || lastState == .thinking {
          totalWorkTime += timeSpent
        }
      }
      lastTimestamp = entry.timestamp
      lastState = entry.state
    }

    // Add the time since the last recorded state if it was a working state.
    if let lastTimestamp = lastTimestamp, let lastState = lastState,
      lastState == .working || lastState == .thinking
    {
      totalWorkTime += Date().timeIntervalSince(lastTimestamp)
    }

    return totalWorkTime
  }

  // MARK: - Nested Types

  /// A struct to represent a single entry in the state history log.
  struct StateHistoryEntry: Encodable {
    let timestamp: Date
    let state: ExerciseState

    enum CodingKeys: String, CodingKey {
      case timestamp, state
    }

    init(timestamp: Date, state: ExerciseState) {
      self.timestamp = timestamp
      self.state = state
    }

    /// Converts the entry to a dictionary for JSON serialization.
    func toDictionary() -> [String: Any] {
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
      dateFormatter.timeZone = TimeZone(identifier: "Europe/Zurich")
      let timestampString = dateFormatter.string(from: timestamp)
      return [
        "timestamp": timestampString,
        "state": state.rawValue,
      ]
    }

    /// Custom encoding to format the date as a string.
    func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
      dateFormatter.timeZone = TimeZone(identifier: "Europe/Zurich")
      let timestampString = dateFormatter.string(from: timestamp)
      try container.encode(timestampString, forKey: .timestamp)
      try container.encode(state.rawValue, forKey: .state)
    }
  }

  /// An enum representing the different types of haptic feedback available.
  enum HapticFeedbackType: String, Codable {
    case startFB = "startFB"
    case pauseFB = "pauseFB"
    case endFB = "endFB"
    case negFB = "negFB"
    case posFB = "posFB"
    case none = "none"
  }

  /// An enum representing all possible states during an exercise session.
  enum ExerciseState: String, Codable {
    case ready = "ready"
    case working = "working"
    case thinking = "thinking"
    case pausing = "pausing"
    case disrupted = "disrupted"
    case ended = "ended"
    case backToWork = "backToWork"
    // States for logging haptic feedback events
    case startFB = "startFB"
    case pauseFB = "pauseFB"
    case endFB = "endFB"
    case negFB = "negFB"
    case posFB = "posFB"
    case none = "none"

    /// A user-facing description for each state.
    var description: String {
      switch self {
      case .working, .backToWork: return "Weiter so!"
      case .thinking, .ready: return "Nachdenken"
      case .disrupted: return "Bist du abgelenkt?"
      case .pausing: return "Pause"
      case .ended: return "Übung beendet"
      case .startFB, .pauseFB, .endFB, .negFB, .posFB, .none: return self.rawValue
      }
    }

    /// A color associated with each state for UI representation.
    var color: Color {
      switch self {
      case .working, .thinking, .ready, .backToWork: return .blue
      case .disrupted: return .yellow
      case .pausing, .ended: return .green
      default: return .black
      }
    }
  }
}

// MARK: - EMA Result History
/// A struct to represent a single entry of the EMA (Ecological Momentary Assessment) model's result.
struct EmaResHistoryEntry: Codable {
  let timestamp: Date
  var proba: Float
  var status: Int

  enum CodingKeys: String, CodingKey {
    case timestamp, proba, status
  }

  /// Custom encoding to format the date as a string.
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    dateFormatter.timeZone = TimeZone(identifier: "Europe/Zurich")
    let timestampString = dateFormatter.string(from: timestamp)

    try container.encode(timestampString, forKey: .timestamp)
    try container.encode(proba, forKey: .proba)
    try container.encode(status, forKey: .status)
  }

  /// Converts the entry to a dictionary for JSON serialization.
  func toDictionary() -> [String: Any] {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    dateFormatter.timeZone = TimeZone(identifier: "Europe/Zurich")
    let timestampString = dateFormatter.string(from: self.timestamp)

    return [
      "timestamp": timestampString,
      "proba": self.proba,
      "status": self.status,
    ]
  }
}
