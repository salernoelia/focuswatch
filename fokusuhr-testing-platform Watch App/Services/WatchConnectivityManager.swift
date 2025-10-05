import Foundation
import WatchConnectivity

final class WatchConnectivityManager: NSObject, ObservableObject {
    weak var delegate: WatchConnectivityDelegate?
    
    override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            #if DEBUG
            ErrorLogger.log(AppError.watchMessageFailed(underlying: error))
            #endif
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        handleMessage(message)
        replyHandler(["status": "success"])
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleMessage(message)
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        handleMessage(applicationContext)
    }
    
    private func handleMessage(_ message: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            guard let action = message["action"] as? String else { return }
            
            switch action {
            case "switchToApp":
                if let appIndex = message["appIndex"] as? Int {
                    self?.delegate?.didReceiveSwitchToApp(appIndex)
                }
            case "returnToMainMenu", "wakeUp":
                self?.delegate?.didReceiveReturnToMainMenu()
            case "updateChecklist":
                self?.handleChecklistUpdate(message)
            default:
                break
            }
        }
    }
    
    private func handleChecklistUpdate(_ message: [String: Any]) {
        guard let dataString = message["data"] as? String,
              let data = Data(base64Encoded: dataString) else {
            return
        }
        
        do {
            let checklistData = try JSONDecoder().decode(ChecklistData.self, from: data)
            let imageData = message["imageData"] as? [String: String] ?? [:]
            let forceOverwrite = message["forceOverwrite"] as? Bool ?? false
            
            delegate?.didReceiveChecklistUpdate(checklistData, images: imageData, forceOverwrite: forceOverwrite)
        } catch {
            #if DEBUG
            ErrorLogger.log(AppError.decodingFailed(type: "ChecklistData", underlying: error))
            #endif
        }
    }
}
