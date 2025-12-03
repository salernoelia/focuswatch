import Foundation
import WatchConnectivity

final class AuthSyncService {
    static let shared = AuthSyncService()

    private let transport: ConnectivityTransport

    init(transport: ConnectivityTransport = .shared) {
        self.transport = transport
    }

    func sync() {
        guard WCSession.default.activationState == .activated else { return }
        guard WCSession.default.isReachable else { return }

        var message: [String: Any] = [SyncConstants.Keys.action: SyncConstants.Actions.updateAuth]

        if let session = supabase.auth.currentSession {
            message[SyncConstants.Keys.accessToken] = session.accessToken
            message[SyncConstants.Keys.refreshToken] = session.refreshToken
            message[SyncConstants.Keys.isLoggedIn] = true
        } else {
            message[SyncConstants.Keys.isLoggedIn] = false
        }

        transport.sendMessage(message, replyHandler: nil) { error in
            #if DEBUG
                print("Failed to sync auth to watch: \(error.localizedDescription)")
            #endif
        }
    }
}

