import Foundation
import WatchConnectivity

class WatchConnector: NSObject, ObservableObject, WCSessionDelegate {
    @Published var isConnected = false
    @Published var checklistData = ChecklistData.default
    
    override init() {
        super.init()
        loadChecklistData()
        setupWatchConnectivity()
    }
    
    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else {
            print("WatchConnectivity not supported")
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
            }
        }
    }
    
    private func sendWakeUpMessage() {
        guard WCSession.default.isReachable else { return }
        
        let message = ["action": "wakeUp"]
        WCSession.default.sendMessage(message, replyHandler: { _ in
            print("Wake up message sent successfully")
        }) { error in
            print("Error sending wake up message: \(error.localizedDescription)")
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = activationState == .activated && session.isReachable
            
            if let error = error {
                print("WCSession activation error: \(error.localizedDescription)")
            } else {
                print("WCSession activated with state: \(activationState.rawValue)")
            }
            
            if self.isConnected {
                self.syncChecklistToWatch()
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isConnected = false
            print("WCSession became inactive")
        }
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isConnected = false
            print("WCSession deactivated")
        }
        
        // Try to reactivate
        session.activate()
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isConnected = session.isReachable
            print("WCSession reachability changed: \(session.isReachable)")
            
            if self.isConnected {
                self.syncChecklistToWatch()
            }
        }
    }
    
    func switchToApp(index: Int) {
        guard WCSession.default.isReachable else {
            print("Watch not reachable for switchToApp")
            return
        }
        
        let message = ["action": "switchToApp", "appIndex": index] as [String : Any]
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("Error sending switchToApp message: \(error.localizedDescription)")
        }
    }
    
    func returnToMainMenu() {
        guard WCSession.default.isReachable else {
            print("Watch not reachable for returnToMainMenu")
            return
        }
        
        let message = ["action": "returnToMainMenu"]
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("Error sending returnToMainMenu message: \(error.localizedDescription)")
        }
    }
    
    func updateChecklistData(_ data: ChecklistData) {
        self.checklistData = data
        saveChecklistData()
        forceSyncToWatch()
    }
    
    func forceSyncToWatch() {
        guard WCSession.default.isReachable else {
            print("Watch not reachable for force sync")
            return
        }
        syncChecklistToWatch()
    }
    
    private func syncChecklistToWatch() {
        guard WCSession.default.isReachable else {
            print("Watch not reachable for sync")
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
            
            let galleryStorage = GalleryStorage()
            var imageData: [String: String] = [:]
            
            let usedImageNames = Set(checklistData.checklists.flatMap { checklist in
                checklist.items.map { $0.imageName }
            }.filter { !$0.isEmpty })
            
            for item in galleryStorage.items {
                if usedImageNames.contains(item.label) {
                    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        .appendingPathComponent(item.imagePath)
                    if let data = try? Data(contentsOf: url) {
                        imageData[item.label] = data.base64EncodedString()
                    }
                }
            }
            
            if !imageData.isEmpty {
                message["imageData"] = imageData
                
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: message, options: [])
                    let sizeInKB = Double(jsonData.count) / 1024.0
                    print("Payload size: \(String(format: "%.1f", sizeInKB)) KB")
                    
                    if sizeInKB > 60 {
                        print("Payload too large, sending without images")
                        message.removeValue(forKey: "imageData")
                    }
                } catch {
                    print("Error serializing message for size check: \(error.localizedDescription)")
                    message.removeValue(forKey: "imageData")
                }
            }
            
            print("Sending force sync with \(checklistData.checklists.count) checklists")
            
            WCSession.default.sendMessage(message, replyHandler: { response in
                print("Checklist force sync successful: \(response)")
            }) { error in
                print("Error force syncing checklist: \(error.localizedDescription)")
            }
        } catch {
            print("Error encoding checklist: \(error.localizedDescription)")
        }
    }
    
    private func saveChecklistData() {
        do {
            let data = try JSONEncoder().encode(checklistData)
            UserDefaults.standard.set(data, forKey: "checklistData")
        } catch {
            print("Error saving checklist data: \(error.localizedDescription)")
        }
    }
    
    private func loadChecklistData() {
        guard let data = UserDefaults.standard.data(forKey: "checklistData") else {
            checklistData = ChecklistData.default
            saveChecklistData()
            return
        }
        
        do {
            checklistData = try JSONDecoder().decode(ChecklistData.self, from: data)
        } catch {
            print("Error loading checklist data: \(error.localizedDescription)")
            checklistData = ChecklistData.default
            saveChecklistData()
        }
    }
}
