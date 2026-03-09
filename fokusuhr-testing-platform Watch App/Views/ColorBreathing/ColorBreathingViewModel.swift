import SwiftUI
import WatchKit
import Combine

@MainActor
final class ColorBreathingViewModel: ObservableObject {
    enum BreathingPhase {
        case inhale
        case holdIn
        case exhale
        case holdOut

        var title: String {
            switch self {
            case .inhale: return String(localized: "Inhale")
            case .holdIn: return String(localized: "Hold In")
            case .exhale: return String(localized: "Exhale")
            case .holdOut: return String(localized: "Hold Out")
            }
        }
    }

    @Published var scale: CGFloat = 0.5
    @Published var phase: BreathingPhase = .inhale
    @Published var configuration = ColorBreathingConfiguration()
    @Published var currentCycle: Int = 0

    var phaseTitle: String {
        phase.title
    }

    private var isActive = false
    private var breathingTask: Task<Void, Never>?
    private var restartTask: Task<Void, Never>?
    private var configObserver: AnyCancellable?

    init() {
        loadConfiguration()
        setupConfigurationObserver()
    }

    private func loadConfiguration() {
        let configurations = SyncCoordinator.loadAppConfigurations()
        configuration = configurations.colorBreathing
    }

    private func setupConfigurationObserver() {
        configObserver = NotificationCenter.default.publisher(for: .appConfigurationsUpdated)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let self,
                      let configurations = notification.object as? AppConfigurations
                else { return }

                self.configuration = configurations.colorBreathing
            }
    }

    func startBreathing() {
        guard breathingTask == nil else { return }

        isActive = true
        restartTask?.cancel()
        resetStateForStart()

        breathingTask = Task { [weak self] in
            guard let self else { return }
            await self.runBreathingLoop()
        }
    }

    func stopBreathing() {
        isActive = false
        breathingTask?.cancel()
        breathingTask = nil
        restartTask?.cancel()
        restartTask = nil
        resetStateForStop()
    }

    private func resetStateForStart() {
        scale = 0.5
        phase = .inhale
        currentCycle = 1
    }

    private func resetStateForStop() {
        scale = 0.5
        phase = .inhale
        currentCycle = 0
    }

    private func runBreathingLoop() async {
        while isActive && !Task.isCancelled {
            await runInhale()
            guard isActive && !Task.isCancelled else { break }

            if configuration.inhaleHoldSeconds > 0 {
                phase = .holdIn
                await sleep(seconds: configuration.inhaleHoldSeconds)
                guard isActive && !Task.isCancelled else { break }
            }

            await runExhale()
            guard isActive && !Task.isCancelled else { break }

            if configuration.exhaleHoldSeconds > 0 {
                phase = .holdOut
                await sleep(seconds: configuration.exhaleHoldSeconds)
                guard isActive && !Task.isCancelled else { break }
            }

            if configuration.cycleCount > 0, currentCycle >= configuration.cycleCount {
                scheduleRestart()
                break
            }

            currentCycle += 1
        }

        breathingTask = nil
    }

    private func runInhale() async {
        phase = .inhale
        if configuration.vibrationOnTransition {
            vibrate()
        }
        withAnimation(.linear(duration: Double(configuration.inhaleSeconds))) {
            scale = 1.2
        }
        await sleep(seconds: configuration.inhaleSeconds)
    }

    private func runExhale() async {
        phase = .exhale
        if configuration.vibrationOnTransition {
            vibrate()
        }
        withAnimation(.linear(duration: Double(configuration.exhaleSeconds))) {
            scale = 0.5
        }
        await sleep(seconds: configuration.exhaleSeconds)
    }

    private func sleep(seconds: Int) async {
        let safeSeconds = max(0, seconds)
        guard safeSeconds > 0 else { return }
        let nanoseconds = UInt64(safeSeconds) * 1_000_000_000
        try? await Task.sleep(nanoseconds: nanoseconds)
    }

    private func scheduleRestart() {
        isActive = false
        resetStateForStop()
        restartTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard let self, !Task.isCancelled else { return }
            self.startBreathing()
        }
    }

    private func vibrate() {
        WKInterfaceDevice.current().play(configuration.vibrationIntensity.hapticType)
    }
}
