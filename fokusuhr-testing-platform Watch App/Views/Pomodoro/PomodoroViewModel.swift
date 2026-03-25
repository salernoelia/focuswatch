import SwiftUI
import UserNotifications
import WatchKit

@MainActor
class PomodoroViewModel: NSObject, ObservableObject, WKExtendedRuntimeSessionDelegate {
  static let shared = PomodoroViewModel()

  @Published var settings = PomodoroConfig() {
    didSet {
      saveSettings()
      if !isLoadingSettings {
        reset()
      }
    }
  }
  @Published var timeRemaining: Int = 1500
  @Published var isRunning = false
  @Published var currentPhase: PomodoroPhase = .work
  @Published var completedRounds = 0

  private var timerTask: Task<Void, Never>?
  private var extendedRuntimeSession: WKExtendedRuntimeSession?
  private var totalTime: Int = 1500
  private var endDate: Date?
  private var lastTickDate: Date?

  private var isLoadingSettings = false

  private let defaults = UserDefaults.standard

  private override init() {
    super.init()
    loadSettings()
    updateTotalTime()
    requestNotificationPermission()
    setupConfigurationObserver()

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(appDidBecomeActive),
      name: WKExtension.applicationDidBecomeActiveNotification,
      object: nil
    )
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
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

      Task { @MainActor in
        self.applyConfiguration(configurations.pomodoro)
      }
    }
  }

  private func applyConfiguration(_ config: PomodoroConfiguration) {
    isLoadingSettings = true
    settings = PomodoroConfig(
      workMinutes: config.workMinutes,
      shortBreakMinutes: config.shortBreakMinutes,
      longBreakMinutes: config.longBreakMinutes,
      roundsUntilLongBreak: config.roundsUntilLongBreak,
      vibrationFrequency: config.vibrationFrequency,
      vibrationIntensity: config.vibrationIntensity,
      completionVibration: config.completionVibration
    )
    isLoadingSettings = false

    if !isRunning {
      updateTotalTime()
    }

    #if DEBUG
      print("Pomodoro: Applied configuration from iOS")
    #endif
  }

  var timeString: String {
    let minutes = timeRemaining / 60
    let seconds = timeRemaining % 60
    return String(format: "%d:%02d", minutes, seconds)
  }

  var currentPhaseTitle: String {
    currentPhase.title
  }

  var phaseColor: Color {
    currentPhase.color
  }

  var progress: Double {
    guard totalTime > 0 else { return 0 }
    return Double(totalTime - timeRemaining) / Double(totalTime)
  }

  private func saveSettings() {
    if let encoded = try? JSONEncoder().encode(settings) {
      defaults.set(encoded, forKey: "PomodoroConfig")
    }
  }

  private func loadSettings() {
    if let data = defaults.data(forKey: "PomodoroConfig"),
      let decoded = try? JSONDecoder().decode(PomodoroConfig.self, from: data)
    {
      isLoadingSettings = true
      settings = decoded
      isLoadingSettings = false
    }
  }

  private func saveState() {
    defaults.set(timeRemaining, forKey: "timeRemaining")
    defaults.set(isRunning, forKey: "isRunning")
    defaults.set(currentPhase.rawValue, forKey: "currentPhase")
    defaults.set(completedRounds, forKey: "completedRounds")
    defaults.set(totalTime, forKey: "totalTime")
    if let endDate = endDate {
      defaults.set(endDate, forKey: "endDate")
    } else {
      defaults.removeObject(forKey: "endDate")
    }
  }

  func restoreState() {

    let wasRunning = defaults.bool(forKey: "isRunning")
    if isRunning && timerTask != nil {
      stopTimer()
    }

    if let phaseString = defaults.string(forKey: "currentPhase"),
      let phase = PomodoroPhase(rawValue: phaseString)
    {
      currentPhase = phase
    }
    completedRounds = defaults.integer(forKey: "completedRounds")
    totalTime = defaults.integer(forKey: "totalTime")

    if totalTime == 0 {
      updateTotalTime()
    }

    if wasRunning,
      let savedEndDate = defaults.object(forKey: "endDate") as? Date
    {
      let now = Date()
      let remainingSeconds = Int(ceil(savedEndDate.timeIntervalSince(now)))

      if remainingSeconds > 0 {

        timeRemaining = remainingSeconds
        isRunning = true
        startTimer()
      } else if remainingSeconds > -300 {

        timeRemaining = 0
        isRunning = false
        Task {
          await phaseCompleted()
        }
      } else {

        timeRemaining = 0
        isRunning = false
        currentPhase = .work
        completedRounds = 0
        updateTotalTime()
        saveState()
      }
    } else {
      timeRemaining = defaults.integer(forKey: "timeRemaining")
      if timeRemaining == 0 {
        timeRemaining = totalTime
      }
      isRunning = false
    }
  }

  @objc private func appDidBecomeActive() {

    if defaults.object(forKey: "endDate") != nil {
      restoreState()
    }
  }

  private func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
      granted, error in
      if let error = error {
        print("Notification permission error: \(error)")
      }
    }
  }

  private func scheduleTimerNotification() {
    let center = UNUserNotificationCenter.current()

    let content = UNMutableNotificationContent()
    content.title = currentPhase.title
    content.body = currentPhase == .work ? "Zeit für eine Pause!" : "Zurück zur Arbeit!"
    content.sound = .default
    content.interruptionLevel = .timeSensitive

    let trigger = UNTimeIntervalNotificationTrigger(
      timeInterval: TimeInterval(timeRemaining),
      repeats: false
    )
    let request = UNNotificationRequest(
      identifier: "pomodoroTimer",
      content: content,
      trigger: trigger
    )

    center.add(request) { error in
      if let error = error {
        print("Notification scheduling error: \(error)")
      }
    }
  }

  func toggleTimer() {
    isRunning.toggle()

    if isRunning {
      startTimer()
    } else {
      stopTimer()
    }
    saveState()
  }

  func reset() {
    stopTimer()
    isRunning = false
    currentPhase = .work
    completedRounds = 0
    updateTotalTime()
    saveState()
  }

  private func startTimer() {
    endDate = Date().addingTimeInterval(TimeInterval(timeRemaining))
    lastTickDate = Date()

    scheduleTimerNotification()

    if settings.vibrationFrequency != .never && currentPhase == .work {
      VibrationManager.shared.startPomodoroRandomVibrations(
        intervalRange: settings.vibrationFrequency.intervalRange,
        intensity: settings.vibrationIntensity.hapticType
      )
    }

    if let existingSession = extendedRuntimeSession {
      if existingSession.state == .running {
      } else {
        extendedRuntimeSession = nil
      }
    }

    if extendedRuntimeSession == nil {
      let session = WKExtendedRuntimeSession()
      session.delegate = self
      extendedRuntimeSession = session
      session.start()
    }

    #if DEBUG
      print("Pomodoro: Timer started, phase=\(currentPhase), remaining=\(timeRemaining)s, vibrations=\(settings.vibrationFrequency != .never && currentPhase == .work)")
    #endif

    timerTask = Task {
      while !Task.isCancelled {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        if !Task.isCancelled {
          await tick()
        }

        if timeRemaining <= 0 {
          break
        }
      }
      if !Task.isCancelled && timeRemaining <= 0 {
        await phaseCompleted()
      }
    }
  }

  private func stopTimer() {
    timerTask?.cancel()
    timerTask = nil
    endDate = nil
    lastTickDate = nil

    // Always stop vibrations when timer stops
    VibrationManager.shared.stopPomodoroRandomVibrations()

    if let session = extendedRuntimeSession {
      if session.state == .running {
        session.invalidate()
      }
      extendedRuntimeSession = nil
    }

    let center = UNUserNotificationCenter.current()
    center.removePendingNotificationRequests(withIdentifiers: ["pomodoroTimer"])

    #if DEBUG
      print("Pomodoro: Timer stopped")
    #endif
  }

  private func tick() async {
    let now = Date()

    if let lastTick = lastTickDate {
      let timeSinceLastTick = now.timeIntervalSince(lastTick)
      if timeSinceLastTick < 0.9 {
        return
      }
    }

    lastTickDate = now

    if let endDate = endDate {
      let remaining = Int(ceil(endDate.timeIntervalSince(now)))
      timeRemaining = max(0, remaining)
    } else {
      timeRemaining = max(0, timeRemaining - 1)
    }

    if timeRemaining % 10 == 0 {
      saveState()
    }
  }

  private func phaseCompleted() async {
    stopTimer()
    isRunning = false

    // Play completion vibration if enabled
    if settings.completionVibration {
      VibrationManager.shared.playHaptic(.notification)
    }

    switch currentPhase {
    case .work:
      completedRounds += 1
      if completedRounds % settings.roundsUntilLongBreak == 0 {
        currentPhase = .longBreak
      } else {
        currentPhase = .shortBreak
      }
    case .shortBreak, .longBreak:
      currentPhase = .work
    }

    #if DEBUG
      print("Pomodoro: Phase completed, new phase=\(currentPhase), rounds=\(completedRounds)")
    #endif

    updateTotalTime()
    saveState()
  }

  func handleTimerCompletion() async {
    await phaseCompleted()
  }

  func skipToBreak() {
    guard currentPhase == .work else { return }
    stopTimer()
    completedRounds += 1
    if completedRounds % settings.roundsUntilLongBreak == 0 {
      currentPhase = .longBreak
    } else {
      currentPhase = .shortBreak
    }
    updateTotalTime()
    saveState()
  }

  func skipToWork() {
    guard currentPhase != .work else { return }
    stopTimer()
    currentPhase = .work
    updateTotalTime()
    saveState()
  }


  private func updateTotalTime() {
    switch currentPhase {
    case .work:
      totalTime = settings.workMinutes * 60
    case .shortBreak:
      totalTime = settings.shortBreakMinutes * 60
    case .longBreak:
      totalTime = settings.longBreakMinutes * 60
    }
    timeRemaining = totalTime
  }

  nonisolated func extendedRuntimeSessionDidStart(_ session: WKExtendedRuntimeSession) {}
  nonisolated func extendedRuntimeSessionWillExpire(_ session: WKExtendedRuntimeSession) {}
  nonisolated func extendedRuntimeSession(
    _ session: WKExtendedRuntimeSession,
    didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
    error: Error?
  ) {
    Task { @MainActor in
      self.extendedRuntimeSession = nil
    }
  }
}

