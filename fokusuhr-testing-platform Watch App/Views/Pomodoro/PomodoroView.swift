import SwiftUI
import UserNotifications
import WatchKit


struct PomodoroView: View {
    @ObservedObject var viewModel = PomodoroViewModel.shared // Use singleton
    
    var body: some View {
        TabView {
            TimerView(viewModel: viewModel)
            SettingsView(viewModel: viewModel)
        }
        .tabViewStyle(.page)
        .onAppear {
            viewModel.restoreState()
        }
    }
}

struct TimerView: View {
    @ObservedObject var viewModel: PomodoroViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Text(viewModel.currentPhaseTitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            Text(viewModel.timeString)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .monospacedDigit()
            
            ProgressView(value: viewModel.progress)
                .tint(viewModel.phaseColor)
                .padding(.horizontal, 8)
            
            HStack(spacing: 16) {
                Button(action: viewModel.toggleTimer) {
                    Image(systemName: viewModel.isRunning ? "pause.fill" : "play.fill")
                        .font(.title2)
                }
                .buttonStyle(.borderedProminent)
                .tint(viewModel.phaseColor)
                
                Button(action: viewModel.reset) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 4)
            
            Text("Wische für Einstellungen →")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
        .padding()
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: PomodoroViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Einstellungen")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 12) {
                    SettingRow(
                        title: "Fokuszeit",
                        value: $viewModel.settings.workMinutes,
                        range: 1...60,
                        unit: "Min"
                    )
                    
                    SettingRow(
                        title: "Kurze Pause",
                        value: $viewModel.settings.shortBreakMinutes,
                        range: 1...15,
                        unit: "Min"
                    )
                    
                    SettingRow(
                        title: "Lange Pause",
                        value: $viewModel.settings.longBreakMinutes,
                        range: 1...30,
                        unit: "Min"
                    )
                    
                    SettingRow(
                        title: "Runden",
                        value: $viewModel.settings.roundsUntilLongBreak,
                        range: 2...8,
                        unit: ""
                    )
                }
            }
            .padding()
        }
    }
}

struct SettingRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack {
                Button {
                    if value > range.lowerBound {
                        value -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .disabled(value <= range.lowerBound)
                
                Spacer()
                
                Text("\(value) \(unit)")
                    .font(.body)
                    .monospacedDigit()
                
                Spacer()
                
                Button {
                    if value < range.upperBound {
                        value += 1
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .disabled(value >= range.upperBound)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Models
struct PomodoroSettings: Codable {
    var workMinutes: Int = 25
    var shortBreakMinutes: Int = 5
    var longBreakMinutes: Int = 15
    var roundsUntilLongBreak: Int = 4
}

enum PomodoroPhase: String, Codable {
    case work
    case shortBreak
    case longBreak
    
    var title: String {
        switch self {
        case .work: return "Fokuszeit"
        case .shortBreak: return "Kurze Pause"
        case .longBreak: return "Lange Pause"
        }
    }
    
    var color: Color {
        switch self {
        case .work: return .blue
        case .shortBreak: return .green
        case .longBreak: return .purple
        }
    }
}


@MainActor
class PomodoroViewModel: ObservableObject {
    static let shared = PomodoroViewModel()
    
    @Published var settings = PomodoroSettings() {
        didSet {
            saveSettings()
            if !isRunning {
                updateTotalTime()
            }
        }
    }
    @Published var timeRemaining: Int = 1500
    @Published var isRunning = false
    @Published var currentPhase: PomodoroPhase = .work
    @Published var completedRounds = 0
    
    private var timerTask: Task<Void, Never>?
    private var totalTime: Int = 1500
    private var endDate: Date?
    private var lastTickDate: Date?
    
    private let defaults = UserDefaults.standard
    
    private init() {
        loadSettings()
        updateTotalTime()
        requestNotificationPermission()
        
        // Restore state when app becomes active
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
    
    // MARK: - Persistence
    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            defaults.set(encoded, forKey: "pomodoroSettings")
        }
    }
    
    private func loadSettings() {
        if let data = defaults.data(forKey: "pomodoroSettings"),
           let decoded = try? JSONDecoder().decode(PomodoroSettings.self, from: data) {
            settings = decoded
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
        // Stop any existing timer first to avoid conflicts
        let wasRunning = defaults.bool(forKey: "isRunning")
        if isRunning && timerTask != nil {
            stopTimer()
        }
        
        if let phaseString = defaults.string(forKey: "currentPhase"),
           let phase = PomodoroPhase(rawValue: phaseString) {
            currentPhase = phase
        }
        completedRounds = defaults.integer(forKey: "completedRounds")
        totalTime = defaults.integer(forKey: "totalTime")
        
        if totalTime == 0 {
            updateTotalTime()
        }
        
        // Check if timer was running
        if wasRunning,
           let savedEndDate = defaults.object(forKey: "endDate") as? Date {
            let now = Date()
            let remainingSeconds = Int(ceil(savedEndDate.timeIntervalSince(now)))
            
            if remainingSeconds > 0 {
                // Timer still running
                timeRemaining = remainingSeconds
                isRunning = true
                startTimer()
            } else if remainingSeconds > -300 {
                // Timer expired recently (within 5 minutes) - complete the phase
                timeRemaining = 0
                isRunning = false
                Task {
                    await phaseCompleted()
                }
            } else {
                // Timer expired long ago - just reset
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
        // Only restore if we haven't already initialized properly
        if defaults.object(forKey: "endDate") != nil {
            restoreState()
        }
    }
    
    // MARK: - Notifications
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    private func scheduleTimerNotification() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        let content = UNMutableNotificationContent()
        content.title = currentPhase.title
        content.body = currentPhase == .work ? "Zeit für eine Pause!" : "Zurück zur Arbeit!"
        content.sound = .default
        
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
    
    // MARK: - Timer Control
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
        
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if !Task.isCancelled {
                    await tick()
                }
                // Check if timer completed
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
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    private func tick() async {
        let now = Date()
        
        // Prevent double-ticking by checking if enough time has passed
        if let lastTick = lastTickDate {
            let timeSinceLastTick = now.timeIntervalSince(lastTick)
            if timeSinceLastTick < 0.9 {
                // Too soon, skip this tick
                return
            }
        }
        
        lastTickDate = now
        
        // Always use endDate as source of truth
        if let endDate = endDate {
            let remaining = Int(ceil(endDate.timeIntervalSince(now)))
            timeRemaining = max(0, remaining)
        } else {
            // Fallback if endDate is missing
            timeRemaining = max(0, timeRemaining - 1)
        }
        
        // Save state periodically (every 10 seconds)
        if timeRemaining % 10 == 0 {
            saveState()
        }
    }
    
    private func phaseCompleted() async {
        stopTimer()
        isRunning = false
        
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
        
        updateTotalTime()
        saveState()
        WKInterfaceDevice.current().play(.notification)
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
}

#Preview {
    PomodoroView()
}
