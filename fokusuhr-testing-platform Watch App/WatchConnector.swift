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
    @Published var checklistConfiguration = ChecklistConfiguration.default
    
    override init() {
        super.init()
        loadChecklistConfiguration()
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
                    if let appIndex = message["appIndex"] as? Int {
                        self.currentView = .app(appIndex)
                    }
                case "returnToMainMenu", "wakeUp":
                    self.currentView = .mainMenu
                case "updateChecklist":
                    if let data = message["data"] as? Data {
                        self.updateChecklistConfiguration(from: data)
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
    
    private func updateChecklistConfiguration(from data: Data) {
        do {
            checklistConfiguration = try JSONDecoder().decode(ChecklistConfiguration.self, from: data)
            saveChecklistConfiguration()
        } catch {
            print("Error decoding checklist configuration: \(error.localizedDescription)")
        }
    }
    
    private func saveChecklistConfiguration() {
        do {
            let data = try JSONEncoder().encode(checklistConfiguration)
            UserDefaults.standard.set(data, forKey: "checklistConfiguration")
        } catch {
            print("Error saving checklist configuration: \(error.localizedDescription)")
        }
    }
    
    private func loadChecklistConfiguration() {
        guard let data = UserDefaults.standard.data(forKey: "checklistConfiguration") else {
            return
        }
        
        do {
            checklistConfiguration = try JSONDecoder().decode(ChecklistConfiguration.self, from: data)
        } catch {
            print("Error loading checklist configuration: \(error.localizedDescription)")
            checklistConfiguration = ChecklistConfiguration.default
            saveChecklistConfiguration()
        }
    }
}
