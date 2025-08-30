//
//  WatchConnector.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 26.06.2025.
//

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
                        self.updateChecklistData(from: data)
                    }
                    // Handle image data transfer
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
    
    private func updateChecklistData(from data: Data) {
        do {
            checklistData = try JSONDecoder().decode(ChecklistData.self, from: data)
            saveChecklistData()
        } catch {
            print("Error decoding checklist data: \(error.localizedDescription)")
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
