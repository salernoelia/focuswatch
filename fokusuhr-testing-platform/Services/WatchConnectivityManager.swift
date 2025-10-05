import Foundation
import WatchConnectivity

final class WatchConnectivityManager: NSObject, ObservableObject {
    weak var delegate: WatchConnectivityDelegate?
    
    override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        guard WCSession.isSupported() else {
            delegate?.didEncounterError(.watchNotSupported)
            #if DEBUG
            ErrorLogger.log(.watchNotSupported)
            #endif
            return
        }
        
        WCSession.default.delegate = self
        WCSession.default.activate()
    }
    
    func forceReconnect() {
        guard WCSession.isSupported() else { return }
        
        if WCSession.default.activationState != .activated {
            WCSession.default.activate()
        }
        
        DispatchQueue.main.async {
            let isConnected = WCSession.default.activationState == .activated && WCSession.default.isReachable
            self.delegate?.didUpdateConnectionState(isConnected)
            
            if isConnected {
                self.sendWakeUpMessage()
            }
        }
    }
    
    func resetSession() {
        guard WCSession.isSupported() else { return }
        
        #if DEBUG
        print("Resetting Watch Connectivity...")
        #endif
        
        if WCSession.default.activationState == .activated {
            WCSession.default.delegate = nil
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.Timing.mediumDelay) {
            WCSession.default.delegate = self
            WCSession.default.activate()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.Timing.longDelay) {
                let isConnected = WCSession.default.activationState == .activated && WCSession.default.isReachable
                self.delegate?.didUpdateConnectionState(isConnected)
                
                #if DEBUG
                print("Reset complete - Connected: \(isConnected)")
                print("Activation State: \(WCSession.default.activationState.rawValue)")
                print("Is Reachable: \(WCSession.default.isReachable)")
                print("Is Paired: \(WCSession.default.isPaired)")
                print("Is Watch App Installed: \(WCSession.default.isWatchAppInstalled)")
                #endif
            }
        }
    }
    
    func sendMessage(_ message: [String: Any], errorHandler: ((AppError) -> Void)? = nil) {
        guard WCSession.default.isReachable else {
            let error = AppError.watchNotReachable
            errorHandler?(error)
            return
        }
        
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            let appError = AppError.watchMessageFailed(underlying: error)
            #if DEBUG
            ErrorLogger.log(appError)
            #endif
            errorHandler?(appError)
        }
    }
    
    func sendMessageWithReply(_ message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void, errorHandler: ((AppError) -> Void)? = nil) {
        guard WCSession.default.isReachable else {
            let error = AppError.watchNotReachable
            errorHandler?(error)
            return
        }
        
        WCSession.default.sendMessage(message, replyHandler: replyHandler) { error in
            let appError = AppError.watchMessageFailed(underlying: error)
            #if DEBUG
            ErrorLogger.log(appError)
            #endif
            errorHandler?(appError)
        }
    }
    
    private func sendWakeUpMessage() {
        let message = ["action": "wakeUp"]
        sendMessageWithReply(message, replyHandler: { _ in
            #if DEBUG
            print("Wake up message sent successfully")
            #endif
        })
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            let isConnected = activationState == .activated && session.isReachable
            self.delegate?.didUpdateConnectionState(isConnected)
            
            if let error = error {
                let appError = AppError.watchMessageFailed(underlying: error)
                #if DEBUG
                ErrorLogger.log(appError)
                #endif
                self.delegate?.didEncounterError(appError)
            } else {
                #if DEBUG
                print("WCSession activated with state: \(activationState.rawValue)")
                #endif
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.delegate?.didUpdateConnectionState(false)
            self.delegate?.didEncounterError(.watchSessionInactive)
            
            #if DEBUG
            print("WCSession became inactive")
            #endif
        }
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async {
            self.delegate?.didUpdateConnectionState(false)
            
            #if DEBUG
            print("WCSession deactivated")
            #endif
        }
        
        session.activate()
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.delegate?.didUpdateConnectionState(session.isReachable)
            
            #if DEBUG
            print("WCSession reachability changed: \(session.isReachable)")
            #endif
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleIncomingMessage(message)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        handleIncomingMessage(message)
        replyHandler(["status": "success"])
    }
    
    private func handleIncomingMessage(_ message: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            guard let action = message["action"] as? String else { return }
            
            switch action {
            default:
                break
            }
        }
    }
}
