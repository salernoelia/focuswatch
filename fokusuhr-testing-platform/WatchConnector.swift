import Foundation
import WatchConnectivity

class WatchConnector: NSObject, ObservableObject, WCSessionDelegate {
    @Published var isConnected = false
    @Published var checklistData = ChecklistData.default
    @Published var lastError: AppError?
    
    override init() {
        super.init()
        loadChecklistData()
        setupWatchConnectivity()
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
    
    func forceReconnect() {
        guard WCSession.isSupported() else { return }
        

        if WCSession.default.activationState != .activated {
            WCSession.default.activate()
        }
        

        DispatchQueue.main.async {
            self.isConnected = WCSession.default.activationState == .activated && WCSession.default.isReachable
            
            if self.isConnected {
                self.syncChecklistToWatch()

                self.sendWakeUpMessage()
                self.syncTelemetryToWatch()
            }
        }
    }
    
    func resetWatchConnectivity() {
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
                self.isConnected = WCSession.default.activationState == .activated && WCSession.default.isReachable
                
                #if DEBUG
                print("Reset complete - Connected: \(self.isConnected)")
                print("Activation State: \(WCSession.default.activationState.rawValue)")
                print("Is Reachable: \(WCSession.default.isReachable)")
                print("Is Paired: \(WCSession.default.isPaired)")
                print("Is Watch App Installed: \(WCSession.default.isWatchAppInstalled)")
                #endif
            }
        }
    }
    
    private func sendWakeUpMessage() {
        guard WCSession.default.isReachable else { 
            lastError = .watchNotReachable
            return 
        }
        
        let message = ["action": "wakeUp"]
        WCSession.default.sendMessage(message, replyHandler: { _ in
            #if DEBUG
            print("Wake up message sent successfully")
            #endif
            self.syncAuthToWatch()
        }) { error in
            let appError = AppError.watchMessageFailed(underlying: error)
            #if DEBUG
            ErrorLogger.log(appError)
            #endif
            self.lastError = appError
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = activationState == .activated && session.isReachable
            
            if let error = error {
                let appError = AppError.watchMessageFailed(underlying: error)
                #if DEBUG
                ErrorLogger.log(appError)
                #endif
                self.lastError = appError
            } else {
                #if DEBUG
                print("WCSession activated with state: \(activationState.rawValue)")
                #endif
            }
            
            if self.isConnected {
                self.syncChecklistToWatch()
                self.syncAuthToWatch()
                self.syncTelemetryToWatch()
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isConnected = false
            self.lastError = .watchSessionInactive
            
            #if DEBUG
            print("WCSession became inactive")
            #endif
        }
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isConnected = false
            
            #if DEBUG
            print("WCSession deactivated")
            #endif
        }
        
        session.activate()
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isConnected = session.isReachable
            
            #if DEBUG
            print("WCSession reachability changed: \(session.isReachable)")
            #endif
            
            if self.isConnected {
                self.syncChecklistToWatch()
                self.syncAuthToWatch()
                self.syncTelemetryToWatch()
            }
        }
    }
    
    func switchToApp(index: Int) {
        guard WCSession.default.isReachable else {
            lastError = .watchNotReachable
            #if DEBUG
            print("Watch not reachable for switchToApp")
            #endif
            return
        }
        
        let message = ["action": "switchToApp", "appIndex": index] as [String : Any]
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            let appError = AppError.watchMessageFailed(underlying: error)
            #if DEBUG
            ErrorLogger.log(appError)
            #endif
            self.lastError = appError
        }
    }
    
    func returnToMainMenu() {
        guard WCSession.default.isReachable else {
            lastError = .watchNotReachable
            #if DEBUG
            print("Watch not reachable for returnToMainMenu")
            #endif
            return
        }
        
        let message = ["action": "returnToMainMenu"]
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            let appError = AppError.watchMessageFailed(underlying: error)
            #if DEBUG
            ErrorLogger.log(appError)
            #endif
            self.lastError = appError
        }
    }
    
    func updateChecklistData(_ data: ChecklistData) {
        self.checklistData = data
        saveChecklistData()
        forceSyncToWatch()
    }
    
    func forceSyncToWatch() {
        guard WCSession.default.isReachable else {
            lastError = .watchNotReachable
            #if DEBUG
            print("Watch not reachable for force sync")
            #endif
            return
        }
        syncChecklistToWatch()
    }
    
    private func syncChecklistToWatch() {
        guard WCSession.default.isReachable else {
            lastError = .watchNotReachable
            #if DEBUG
            print("Watch not reachable for sync")
            #endif
            return
        }
        
        do {
            let data = try JSONEncoder().encode(checklistData)
            var message: [String: Any] = [
                "action": "updateChecklist", 
                "data": data.base64EncodedString(),
                "forceOverwrite": true,
                "timestamp": Date().timeIntervalSince1970
            ]
            
            let galleryStorage = GalleryStorage.shared
            var imageData: [String: String] = [:]
            
            let usedImageNames = Set(checklistData.checklists.flatMap { checklist in
                checklist.items.map { $0.imageName }
            }.filter { !$0.isEmpty })
            
            for item in galleryStorage.items {
                guard usedImageNames.contains(item.label) else { continue }
                
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                guard let documentsURL = documentsURL else { continue }
                
                let url = documentsURL.appendingPathComponent(item.imagePath)
                
                guard FileManager.default.fileExists(atPath: url.path),
                      let data = try? Data(contentsOf: url) else { continue }
                
                imageData[item.label] = data.base64EncodedString()
            }
            
            if !imageData.isEmpty {
                message["imageData"] = imageData
                
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: message, options: [])
                    let sizeInKB = Double(jsonData.count) / AppConstants.Network.bytesToKBDivisor
                    
                    #if DEBUG
                    print("Payload size: \(String(format: "%.1f", sizeInKB)) KB")
                    #endif
                    
                    if sizeInKB > AppConstants.Network.maxPayloadSizeKB {
                        #if DEBUG
                        print("Payload too large, sending without images")
                        #endif
                        message.removeValue(forKey: "imageData")
                    }
                } catch {
                    let appError = AppError.encodingFailed(type: "sync message", underlying: error)
                    #if DEBUG
                    ErrorLogger.log(appError)
                    #endif
                    message.removeValue(forKey: "imageData")
                }
            }
            
            #if DEBUG
            print("Sending force sync with \(checklistData.checklists.count) checklists")
            #endif
            
            WCSession.default.sendMessage(message, replyHandler: { response in
                #if DEBUG
                print("Checklist force sync successful: \(response)")
                #endif
            }) { error in
                let appError = AppError.watchMessageFailed(underlying: error)
                #if DEBUG
                ErrorLogger.log(appError)
                #endif
                self.lastError = appError
            }
        } catch {
            let appError = AppError.encodingFailed(type: "checklist", underlying: error)
            #if DEBUG
            ErrorLogger.log(appError)
            #endif
            lastError = appError
        }
    }
    
    private func saveChecklistData() {
        do {
            let data = try JSONEncoder().encode(checklistData)
            UserDefaults.standard.set(data, forKey: AppConstants.StorageKeys.checklistData)
        } catch {
            let appError = AppError.encodingFailed(type: "checklist data", underlying: error)
            #if DEBUG
            ErrorLogger.log(appError)
            #endif
            lastError = appError
        }
    }
    
    private func loadChecklistData() {
        guard let data = UserDefaults.standard.data(forKey: AppConstants.StorageKeys.checklistData) else {
            checklistData = ChecklistData.default
            saveChecklistData()
            return
        }
        
        do {
            checklistData = try JSONDecoder().decode(ChecklistData.self, from: data)
        } catch {
            let appError = AppError.decodingFailed(type: "checklist data", underlying: error)
            #if DEBUG
            ErrorLogger.log(appError)
            #endif
            lastError = appError
            checklistData = ChecklistData.default
            saveChecklistData()
        }
    }
    
    private func syncAuthToWatch() {
        guard WCSession.default.isReachable else { return }
        
        var message: [String: Any] = ["action": "updateAuth"]
        
        if let session = supabase.auth.currentSession {
            message["accessToken"] = session.accessToken
            message["refreshToken"] = session.refreshToken
            message["isLoggedIn"] = true
        } else {
            message["isLoggedIn"] = false
        }
        
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            #if DEBUG
            print("Failed to sync auth to watch: \(error.localizedDescription)")
            #endif
        }
    }
    
    private func syncTelemetryToWatch() {
        guard WCSession.default.isReachable else { return }
        
        let message: [String: Any] = [
            "action": "updateTelemetry",
            "hasConsent": TelemetryManager.shared.hasConsent
        ]
        
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            #if DEBUG
            print("Failed to sync telemetry to watch: \(error.localizedDescription)")
            #endif
        }
    }
}
