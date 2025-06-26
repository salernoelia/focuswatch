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
    
    override init() {
        super.init()
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
                case "returnToMainMenu":
                    self.currentView = .mainMenu
                default:
                    break
                }
            }
        }
    }
}
