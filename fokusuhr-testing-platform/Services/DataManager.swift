import Foundation
import Combine
import SwiftUI

class DataManager: ObservableObject {
    @Published var apps: [AppInfo] = []
    @Published var testUsers: [TestUser] = []
    @Published var isLoading = false
    
    static let shared = DataManager()
    
    private init() {
        loadDefaultData()
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
    

    func fetchTestUsers() async {
        await MainActor.run { isLoading = true }
        
        // TODO: Replace with Supabase API call & refactor into own model class
        await MainActor.run {
            testUsers = getDefaultUsers()
            isLoading = false
        }
    }
    
    private func getDefaultUsers() -> [TestUser] {
        return [
            TestUser(id: 1, first_name: "Jon", last_name: "Doe", age: 29, supervisor_uid: "1"),
            TestUser(id: 2, first_name: "Lina", last_name: "Wong", age: 34, supervisor_uid: "2"),
            TestUser(id: 3, first_name: "Alex", last_name: "Smith", age: 26, supervisor_uid: "1")
        ]
    }
    

    func saveJournalEntry(_ entry: JournalEntry) async -> Bool {
        await MainActor.run { isLoading = true }
        
        // TODO: Replace with Supabase API call & refactor into own model class
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        await MainActor.run { isLoading = false }
        return true
    }
    
    func fetchJournalEntries() async -> [JournalEntry] {
        await MainActor.run { isLoading = true }
        
        // TODO: Replace with Supabase API call & refactor into own model class
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        await MainActor.run { isLoading = false }
        return []
    }
    
    private func loadDefaultData() {
        Task {
            await fetchApps()
            await fetchTestUsers()
        }
    }
}




