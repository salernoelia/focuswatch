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
    
    func updateChecklistConfiguration(_ configuration: ChecklistConfiguration) {
        self.checklistConfiguration = configuration
        saveChecklistConfiguration()
        syncChecklistToWatch()
    }
    
    private func syncChecklistToWatch() {
        guard WCSession.default.isReachable else { return }
        
        do {
            let data = try JSONEncoder().encode(checklistConfiguration)
            let message = ["action": "updateChecklist", "data": data] as [String : Any]
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("Error syncing checklist: \(error.localizedDescription)")
            }
        } catch {
            print("Error encoding checklist: \(error.localizedDescription)")
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
