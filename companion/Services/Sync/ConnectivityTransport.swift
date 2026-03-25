import Combine
import Foundation
import WatchConnectivity

final class ConnectivityTransport: NSObject, ObservableObject {
    static let shared = ConnectivityTransport()

    @Published private(set) var isConnected = false
    @Published private(set) var isReachable = false
    @Published private(set) var isPaired = false
    @Published private(set) var isWatchAppInstalled = false
    @Published var lastError: AppError?

    let contextReceived = PassthroughSubject<[String: Any], Never>()
    let messageReceived = PassthroughSubject<([String: Any], (([String: Any]) -> Void)?), Never>()
    let userInfoReceived = PassthroughSubject<[String: Any], Never>()
    let fileReceived = PassthroughSubject<(URL, [String: Any]?), Never>()
    let fileTransferFinished = PassthroughSubject<(WCSessionFileTransfer, Error?), Never>()

    private var connectionMonitorTimer: Timer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private var isMonitoringConnection = false
    private let applicationContextQueue = DispatchQueue(label: "com.fokusuhr.sync.applicationContext")

    override private init() {
        super.init()
        setupWatchConnectivity()
        startConnectionMonitoring()
    }

    deinit {
        stopConnectionMonitoring()
    }

    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else {
            lastError = .watchNotSupported
            #if DEBUG
                ErrorLogger.log(.watchNotSupported)
            #endif
            return
        }

        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    private func startConnectionMonitoring() {
        guard !isMonitoringConnection else { return }
        isMonitoringConnection = true

        connectionMonitorTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
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
        let shouldBeConnected = session.activationState == .activated

        if shouldBeConnected != isConnected {
            DispatchQueue.main.async {
                self.isConnected = shouldBeConnected
                self.updateSessionState(session)
            }
        }

        if !isConnected && session.activationState != .activated {
            scheduleReconnectIfNeeded()
        }
    }

    private func updateSessionState(_ session: WCSession) {
        isReachable = session.isReachable
        isPaired = session.isPaired
        isWatchAppInstalled = session.isWatchAppInstalled
    }

    private func scheduleReconnectIfNeeded() {
        guard reconnectAttempts < maxReconnectAttempts else {
            #if DEBUG
                print("Max reconnect attempts reached")
            #endif
            return
        }

        reconnectAttempts += 1
        let delay = min(Double(reconnectAttempts) * 2.0, 10.0)

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.attemptReconnect()
        }
    }

    private func attemptReconnect() {
        guard WCSession.isSupported() else { return }

        let session = WCSession.default

        if session.activationState != .activated {
            session.activate()
        } else {
            DispatchQueue.main.async {
                self.isConnected = true
                self.reconnectAttempts = 0
                self.updateSessionState(session)
            }
        }
    }

    func forceReconnect() {
        guard WCSession.isSupported() else { return }

        let session = WCSession.default

        if session.activationState != .activated {
            session.activate()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isConnected = session.activationState == .activated
            self.updateSessionState(session)

            if self.isConnected {
                self.reconnectAttempts = 0
            } else {
                self.scheduleReconnectIfNeeded()
            }
        }
    }

    func updateApplicationContext(_ context: [String: Any]) throws {
        guard WCSession.default.activationState == .activated else {
            throw AppError.watchSessionInactive
        }

        var resultError: Error?
        applicationContextQueue.sync {
            do {
                var mergedContext = WCSession.default.applicationContext
                for (key, value) in context {
                    mergedContext[key] = value
                }
                try WCSession.default.updateApplicationContext(mergedContext)
            } catch {
                resultError = error
            }
        }

        if let resultError {
            throw resultError
        }
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

    @discardableResult
    func transferFile(_ fileURL: URL, metadata: [String: Any]?) -> WCSessionFileTransfer? {
        guard WCSession.default.activationState == .activated else {
            lastError = .watchSessionInactive
            #if DEBUG
                print("iOS ConnectivityTransport: Cannot transfer file - session inactive")
            #endif
            return nil
        }

        let transfer = WCSession.default.transferFile(fileURL, metadata: metadata)
        #if DEBUG
            if let imageName = metadata?[SyncConstants.Keys.imageName] as? String {
                print("iOS ConnectivityTransport: Queued file transfer for \(imageName)")
                print("iOS ConnectivityTransport: Outstanding transfers: \(WCSession.default.outstandingFileTransfers.count)")
            }
        #endif
        return transfer
    }

    func outstandingFileTransfers() -> [WCSessionFileTransfer] {
        WCSession.default.outstandingFileTransfers
    }

    func cancelAllFileTransfers() {
        for transfer in WCSession.default.outstandingFileTransfers {
            transfer.cancel()
        }
    }
}

extension ConnectivityTransport: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = activationState == .activated
            self.updateSessionState(session)

            if let error = error {
                let appError = AppError.watchMessageFailed(underlying: error)
                #if DEBUG
                    ErrorLogger.log(appError)
                #endif
                self.lastError = appError
                self.scheduleReconnectIfNeeded()
            } else {
                self.reconnectAttempts = 0
            }
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isConnected = false
            self.lastError = .watchSessionInactive
        }
    }

    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isConnected = false
        }
        session.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            if session.isReachable {
                self.reconnectAttempts = 0
            }
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        contextReceived.send(applicationContext)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        messageReceived.send((message, nil))
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        messageReceived.send((message, replyHandler))
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        userInfoReceived.send(userInfo)
    }

    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        fileReceived.send((file.fileURL, file.metadata))
    }

    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        #if DEBUG
            if let imageName = fileTransfer.file.metadata?[SyncConstants.Keys.imageName] as? String {
                if let error = error {
                    print("iOS ConnectivityTransport: File transfer FAILED for \(imageName): \(error.localizedDescription)")
                } else {
                    print("iOS ConnectivityTransport: File transfer SUCCESS for \(imageName)")
                }
            }
        #endif
        fileTransferFinished.send((fileTransfer, error))
    }
}



