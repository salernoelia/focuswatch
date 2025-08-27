//
//  WatchConnector.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 26.06.2025.
// 

import Foundation
import WatchConnectivity

class WatchConnector: NSObject, ObservableObject, WCSessionDelegate {
    @Published var isConnected = false
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
            self.isConnected = activationState == .activated && session.isReachable
            if self.isConnected {
                self.syncChecklistToWatch()
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isConnected = false
        }
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isConnected = false
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isConnected = session.isReachable
            if self.isConnected {
                self.syncChecklistToWatch()
            }
        }
    }
    
    func switchToApp(index: Int) {
        guard WCSession.default.isReachable else { return }
        
        let message = ["action": "switchToApp", "appIndex": index] as [String : Any]
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("Error sending message: \(error.localizedDescription)")
        }
    }
    
    func returnToMainMenu() {
        guard WCSession.default.isReachable else { return }
        
        let message = ["action": "returnToMainMenu"]
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("Error sending message: \(error.localizedDescription)")
        }
    }
    
    func updateChecklistData(_ data: ChecklistData) {
        self.checklistData = data
        saveChecklistData()
        syncChecklistToWatch()
    }
    
    private func syncChecklistToWatch() {
        guard WCSession.default.isReachable else { return }
        
        do {
            let data = try JSONEncoder().encode(checklistData)
            var message: [String: Any] = ["action": "updateChecklist", "data": data.base64EncodedString()]
            
            // Only collect images that are actually used in checklists
            let galleryStorage = GalleryStorage()
            var imageData: [String: String] = [:] // Changed to String for Base64
            
            // Get all image names used in checklists
            let usedImageNames = Set(checklistData.checklists.flatMap { checklist in
                checklist.items.map { $0.imageName }
            }.filter { !$0.isEmpty })
            
            // Only send images that are actually used
            for item in galleryStorage.items {
                if usedImageNames.contains(item.label) {
                    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        .appendingPathComponent(item.imagePath)
                    if let data = try? Data(contentsOf: url) {
                        // Convert Data to Base64 string for JSON serialization
                        imageData[item.label] = data.base64EncodedString()
                    }
                }
            }
            
            if !imageData.isEmpty {
                message["imageData"] = imageData
                
                // Debug: Log payload size
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: message, options: [])
                    let sizeInKB = Double(jsonData.count) / 1024.0
                    print("Payload size: \(String(format: "%.1f", sizeInKB)) KB")
                    
                    // If still too large, skip images
                    if sizeInKB > 60 { // Leave some margin under 65KB limit
                        print("Payload too large, sending without images")
                        message.removeValue(forKey: "imageData")
                    }
                } catch {
                    print("Error serializing message for size check: \(error.localizedDescription)")
                    // If we can't serialize, definitely remove images
                    message.removeValue(forKey: "imageData")
                }
            }
            
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("Error syncing checklist: \(error.localizedDescription)")
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
