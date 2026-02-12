import Foundation
import WatchConnectivity

final class CommandSyncService: ObservableObject {
    static let shared = CommandSyncService()

    @Published var lastError: AppError?

    private let transport: ConnectivityTransport

    init(transport: ConnectivityTransport = .shared) {
        self.transport = transport
    }

    func switchToApp(index: Int) {
        guard WCSession.default.activationState == .activated else { return }

        guard WCSession.default.isReachable else {
            lastError = .watchNotReachable
            return
        }

        let message: [String: Any] = [
            SyncConstants.Keys.action: SyncConstants.Actions.switchToApp,
            SyncConstants.Keys.appIndex: index
        ]

        transport.sendMessage(message, replyHandler: nil) { [weak self] error in
            let appError = AppError.watchMessageFailed(underlying: error)
            #if DEBUG
                ErrorLogger.log(appError)
            #endif
            self?.lastError = appError
        }
    }

    func returnToMainMenu() {
        guard WCSession.default.activationState == .activated else { return }

        guard WCSession.default.isReachable else {
            lastError = .watchNotReachable
            return
        }

        let message = [SyncConstants.Keys.action: SyncConstants.Actions.returnToDashboard]

        transport.sendMessage(message, replyHandler: nil) { [weak self] error in
            let appError = AppError.watchMessageFailed(underlying: error)
            #if DEBUG
                ErrorLogger.log(appError)
            #endif
            self?.lastError = appError
        }
    }

    func sendWakeUpMessage() {
        guard WCSession.default.activationState == .activated else { return }
        guard WCSession.default.isReachable else {
            lastError = .watchNotReachable
            return
        }

        let message = [SyncConstants.Keys.action: SyncConstants.Actions.wakeUp]

        transport.sendMessage(
            message,
            replyHandler: { _ in
                AuthSyncService.shared.sync()
            }
        ) { [weak self] error in
            let appError = AppError.watchMessageFailed(underlying: error)
            #if DEBUG
                ErrorLogger.log(appError)
            #endif
            self?.lastError = appError
        }
    }

    func resetChecklistState(checklistId: UUID) {
        guard WCSession.default.activationState == .activated else { return }

        let message: [String: Any] = [
            SyncConstants.Keys.action: SyncConstants.Actions.resetChecklistState,
            SyncConstants.Keys.checklistId: checklistId.uuidString
        ]

        if WCSession.default.isReachable {
            transport.sendMessage(message, replyHandler: nil) { [weak self] error in
                let appError = AppError.watchMessageFailed(underlying: error)
                #if DEBUG
                    ErrorLogger.log(appError)
                #endif
                self?.lastError = appError
            }
            return
        }

        transport.transferUserInfo(message)
    }
}

