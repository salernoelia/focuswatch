import SwiftUI
import WatchKit

class ColorBreathingViewModel: ObservableObject {
    @Published var scale: CGFloat = 0.5
    @Published var isInhaling: Bool = true
    @Published var configuration = ColorBreathingConfiguration()
    @Published var currentCycle: Int = 0

    private var timer: Timer?

    init() {
        loadConfiguration()
        setupConfigurationObserver()
    }

    private func loadConfiguration() {
        let configurations = SyncCoordinator.loadAppConfigurations()
        configuration = configurations.colorBreathing
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

            self.configuration = configurations.colorBreathing
        }
    }

    func startBreathing() {
        scale = 1.2
        currentCycle = 0
        let intervalSeconds = Double(configuration.inhaleSeconds + configuration.exhaleSeconds)

        timer = Timer.scheduledTimer(withTimeInterval: intervalSeconds, repeats: true) {
            [weak self] _ in
            guard let self = self else { return }

            self.isInhaling.toggle()

            if self.configuration.vibrationOnTransition {
                self.vibrate()
            }

            if !self.isInhaling {
                self.currentCycle += 1

                if self.currentCycle >= self.configuration.cycleCount {
                    self.stopBreathing()
                }
            }
        }
    }

    func stopBreathing() {
        timer?.invalidate()
        timer = nil
        currentCycle = 0
    }

    private func vibrate() {
        WKInterfaceDevice.current().play(configuration.vibrationIntensity.hapticType)
    }
}
