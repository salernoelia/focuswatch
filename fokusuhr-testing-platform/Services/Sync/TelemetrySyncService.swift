import Foundation
import WatchConnectivity

final class TelemetrySyncService {
    static let shared = TelemetrySyncService()

    private let transport: ConnectivityTransport

    init(transport: ConnectivityTransport = .shared) {
        self.transport = transport
    }

    func sync() {
        guard WCSession.default.activationState == .activated else { return }

        let userInfo: [String: Any] = [
            SyncConstants.Keys.action: SyncConstants.Actions.updateTelemetry,
            SyncConstants.Keys.hasConsent: TelemetryManager.shared.hasConsent
        ]

        if WCSession.default.isReachable {
            transport.sendMessage(userInfo, replyHandler: nil) { [weak self] _ in
                self?.fallbackSync(userInfo)
            }
        } else {
            fallbackSync(userInfo)
        }
    }

    private func fallbackSync(_ userInfo: [String: Any]) {
        do {
            try transport.updateApplicationContext(userInfo)
        } catch {
            transport.transferUserInfo(userInfo)
        }
    }
}

