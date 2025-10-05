import Foundation
import WatchConnectivity

class WatchConnector: NSObject, ObservableObject {
    @Published var isConnected = false
    @Published var checklistData = ChecklistData.default
    @Published var lastError: AppError?
    
    private let connectivityManager = WatchConnectivityManager()
    
    override init() {
        super.init()
        loadChecklistData()
        connectivityManager.delegate = self
    }
    
    func forceReconnect() {
        connectivityManager.forceReconnect()
        if isConnected {
            syncChecklistToWatch()
        }
    }
    
    func resetWatchConnectivity() {
        connectivityManager.resetSession()
    }
    
    func switchToApp(index: Int) {
        let message = ["action": "switchToApp", "appIndex": index] as [String : Any]
        connectivityManager.sendMessage(message) { [weak self] error in
            self?.lastError = error
        }
    }
    
    func returnToMainMenu() {
        let message = ["action": "returnToMainMenu"]
        connectivityManager.sendMessage(message) { [weak self] error in
            self?.lastError = error
        }
    }
    
    func updateChecklistData(_ data: ChecklistData) {
        self.checklistData = data
        saveChecklistData()
        forceSyncToWatch()
    }
    
    func forceSyncToWatch() {
        syncChecklistToWatch()
    }
    
    private func syncChecklistToWatch() {
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
            
            connectivityManager.sendMessageWithReply(message, replyHandler: { response in
                #if DEBUG
                print("Checklist force sync successful: \(response)")
                #endif
            }) { [weak self] error in
                self?.lastError = error
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
}

extension WatchConnector: WatchConnectivityDelegate {
    func didUpdateConnectionState(_ isConnected: Bool) {
        self.isConnected = isConnected
        if isConnected {
            syncChecklistToWatch()
        }
    }
    
    func didEncounterError(_ error: AppError) {
        lastError = error
    }
}
