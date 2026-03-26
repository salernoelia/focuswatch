import SwiftUI
import WatchKit
import Combine

@MainActor
final class SpeedometerViewModel: ObservableObject {
    @Published var configuration = FokusMeterConfiguration()

    private var configObserver: AnyCancellable?

    init() {
        loadConfiguration()
        setupConfigurationObserver()
    }

    private func loadConfiguration() {
        let configurations = SyncCoordinator.loadAppConfigurations()
        configuration = configurations.fokusMeter
    }

    private func setupConfigurationObserver() {
        configObserver = NotificationCenter.default.publisher(for: .appConfigurationsUpdated)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let self,
                      let configurations = notification.object as? AppConfigurations
                else { return }

                self.configuration = configurations.fokusMeter
            }
    }
}
