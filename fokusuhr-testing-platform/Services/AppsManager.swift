//
//  AppsManager.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 25.09.2025.
//

import Foundation
import Combine
import SwiftUI

class AppsManager: ObservableObject {
    @Published var apps: [AppInfo] = []
    
    @Published var isLoading = false
    
    static let shared = AppsManager()
    
    private init() {
        Task {
            await fetchApps()
        }
    }
    
    func fetchApps() async {
        await MainActor.run { isLoading = true }
        

        await MainActor.run {
            apps = getDefaultApps()
            isLoading = false
        }
    }
    
    private func getDefaultApps() -> [AppInfo] {
        var apps = [
            AppInfo(title: "Farbatmung", description: "Beruhigende Atemübungen", color: .green),
            AppInfo(title: "Fidget Spinner", description: "Digitaler Fidget Spinner", color: .orange)
        ]
        
        let checklistData = ChecklistManager.loadSharedData()
        for checklist in checklistData.checklists {
            apps.append(AppInfo(title: checklist.name, description: "Interaktive Checkliste", color: .blue))
        }
        
        return apps
    }
    

   

}




