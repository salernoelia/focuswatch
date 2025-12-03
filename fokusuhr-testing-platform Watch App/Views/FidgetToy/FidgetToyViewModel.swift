import Combine
import SwiftUI

class FidgetToyViewModel: ObservableObject {
    @Published var position: CGSize = .zero
    @Published var isMoving: Bool = false
    @Published var configuration = FidgetToyConfiguration()

    private var feedbackTimer: Timer?

    init() {
        loadConfiguration()
        setupConfigurationObserver()
    }

    private func loadConfiguration() {
        let configurations = SyncCoordinator.loadAppConfigurations()
        configuration = configurations.fidgetToy
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

            self.configuration = configurations.fidgetToy
        }
    }

    func startVibration() {
        guard feedbackTimer == nil else { return }

        feedbackTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            WKInterfaceDevice.current().play(self.configuration.vibrationIntensity.hapticType)
        }
    }

    func stopVibration() {
        feedbackTimer?.invalidate()
        feedbackTimer = nil
    }

    func updatePosition(_ value: DragGesture.Value) {
        position = value.translation
        isMoving = true
        startVibration()
    }

    func endDrag() {
        isMoving = false
        position = .zero
        stopVibration()
    }
}
