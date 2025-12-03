import Combine
import Foundation
import WatchConnectivity

final class ConnectivityTransport: NSObject, ObservableObject {
    static let shared = ConnectivityTransport()

    @Published private(set) var isReachable = false

    let contextReceived = PassthroughSubject<[String: Any], Never>()
    let messageReceived = PassthroughSubject<([String: Any], (([String: Any]) -> Void)?), Never>()
    let userInfoReceived = PassthroughSubject<[String: Any], Never>()

    private var connectionMonitorTimer: Timer?
    private var isMonitoringConnection = false

    override private init() {
        super.init()
        setupWatchConnectivity()
        startConnectionMonitoring()
    }

    deinit {
        stopConnectionMonitoring()
    }

    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.loadLatestApplicationContext()
            }
        }
    }

    private func startConnectionMonitoring() {
        guard !isMonitoringConnection else { return }
        isMonitoringConnection = true

        connectionMonitorTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            self?.checkConnectionHealth()
        }
    }

    private func stopConnectionMonitoring() {
        connectionMonitorTimer?.invalidate()
        connectionMonitorTimer = nil
        isMonitoringConnection = false
    }

    private func checkConnectionHealth() {
        guard WCSession.isSupported() else { return }

        let session = WCSession.default

        if session.activationState != .activated {
            session.activate()
        } else if session.isReachable {
            loadLatestApplicationContext()
        }
    }

    func forceReconnect() {
        guard WCSession.isSupported() else { return }

        let session = WCSession.default

        if session.activationState != .activated {
            session.activate()
        } else {
            sendWatchUUIDToiOS()
            loadLatestApplicationContext()
        }
    }

    func loadLatestApplicationContext() {
        let context = WCSession.default.receivedApplicationContext
        if !context.isEmpty {
            contextReceived.send(context)
        }
    }

    func sendWatchUUIDToiOS() {
        let watchUUID = WatchConfig.shared.uuid
        let message: [String: Any] = [
            SyncConstants.Keys.action: SyncConstants.Actions.updateWatchUUID,
            SyncConstants.Keys.watchUUID: watchUUID
        ]

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil) { _ in
                do {
                    try WCSession.default.updateApplicationContext(message)
                } catch {}
            }
        } else {
            do {
                try WCSession.default.updateApplicationContext(message)
            } catch {}
        }
    }

    func updateApplicationContext(_ context: [String: Any]) throws {
        try WCSession.default.updateApplicationContext(context)
    }

    func sendMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)? = nil, errorHandler: ((Error) -> Void)? = nil) {
        guard WCSession.default.activationState == .activated else {
            errorHandler?(AppError.watchSessionInactive)
            return
        }

        guard WCSession.default.isReachable else {
            errorHandler?(AppError.watchNotReachable)
            return
        }

        WCSession.default.sendMessage(message, replyHandler: replyHandler, errorHandler: errorHandler)
    }

    func transferUserInfo(_ userInfo: [String: Any]) {
        guard WCSession.default.activationState == .activated else { return }
        WCSession.default.transferUserInfo(userInfo)
    }

    func getReceivedApplicationContext() -> [String: Any] {
        WCSession.default.receivedApplicationContext
    }
}

extension ConnectivityTransport: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable

            if error == nil && activationState == .activated {
                self.sendWatchUUIDToiOS()
                self.loadLatestApplicationContext()
            }
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            if session.isReachable {
                self.sendWatchUUIDToiOS()
                self.loadLatestApplicationContext()
            }
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard !applicationContext.isEmpty else { return }
        contextReceived.send(applicationContext)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        messageReceived.send((message, nil))
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        messageReceived.send((message, replyHandler))
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard !userInfo.isEmpty else { return }
        userInfoReceived.send(userInfo)
    }
}

