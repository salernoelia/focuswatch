import Foundation
import WatchConnectivity

class WatchConnector: NSObject, ObservableObject, WCSessionDelegate {
    @Published var currentView: WatchViewState = .mainMenu
    @Published var checklistData = ChecklistData.default
    
    override init() {
        super.init()
        loadChecklistData()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                print("Watch WCSession activation error: \(error.localizedDescription)")
            } else {
                print("Watch WCSession activated with state: \(activationState.rawValue)")
                print("Watch session reachable: \(session.isReachable)")

            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        DispatchQueue.main.async {
            if let action = message["action"] as? String {
                switch action {
                case "switchToApp":
                    self.currentView = .mainMenu
                    if let appIndex = message["appIndex"] as? Int {
                        self.currentView = .app(appIndex)
                    }
                    replyHandler(["status": "success"])
                case "returnToMainMenu", "wakeUp":
                    self.currentView = .mainMenu
                    replyHandler(["status": "success"])
                case "updateChecklist":
                    if let dataString = message["data"] as? String,
                       let data = Data(base64Encoded: dataString) {
                        let forceOverwrite = message["forceOverwrite"] as? Bool ?? false
                        self.updateChecklistData(from: data, forceOverwrite: forceOverwrite)
                    }
                    if let imageData = message["imageData"] as? [String: String] {
                        self.saveGalleryImages(imageData)
                    }
                    replyHandler(["status": "success"])
                default:
                    replyHandler(["status": "unknown_action"])
                }
            } else {
                replyHandler(["status": "no_action"])
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let action = message["action"] as? String {
                switch action {
                case "switchToApp":
                    self.currentView = .mainMenu
                    if let appIndex = message["appIndex"] as? Int {
                        self.currentView = .app(appIndex)
                    }
                case "returnToMainMenu", "wakeUp":
                    self.currentView = .mainMenu
                case "updateChecklist":
                    if let dataString = message["data"] as? String,
                       let data = Data(base64Encoded: dataString) {
                        let forceOverwrite = message["forceOverwrite"] as? Bool ?? false
                        self.updateChecklistData(from: data, forceOverwrite: forceOverwrite)
                    }
                    if let imageData = message["imageData"] as? [String: String] {
                        self.saveGalleryImages(imageData)
                    }
                default:
                    break
                }
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            if let action = applicationContext["action"] as? String {
                switch action {
                case "wakeUp":
                    self.currentView = .mainMenu
                default:
                    break
                }
            }
        }
    }
    
    private func updateChecklistData(from data: Data, forceOverwrite: Bool = false) {
        do {
            let newData = try JSONDecoder().decode(ChecklistData.self, from: data)
            
            if forceOverwrite {

                print("Force overwrite: Clearing old data and replacing with new data")
                

                clearOldGalleryImages()
                

                checklistData = newData
                print("Replaced with \(newData.checklists.count) checklists")
            } else {

                checklistData = newData
                print("Updated with \(newData.checklists.count) checklists")
            }
            
            saveChecklistData()
        } catch {
            print("Error decoding checklist data: \(error.localizedDescription)")
        }
    }
    
    private func clearOldGalleryImages() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: nil)
            
            for fileURL in contents {
                if fileURL.pathExtension == "jpg" {
                    try? FileManager.default.removeItem(at: fileURL)
                    print("Removed old image: \(fileURL.lastPathComponent)")
                }
            }
        } catch {
            print("Error clearing old gallery images: \(error.localizedDescription)")
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
    
    private func saveGalleryImages(_ imageData: [String: String]) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        for (imageName, base64String) in imageData {
            if let data = Data(base64Encoded: base64String) {
                let imageURL = documentsPath.appendingPathComponent("\(imageName).jpg")
                try? data.write(to: imageURL)
            }
        }
    }
}
