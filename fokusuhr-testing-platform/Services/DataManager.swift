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
        
        do {
            let users = try await TestUserService.shared.fetchTestUsers()
            await MainActor.run {
                self.testUsers = users
                isLoading = false
            }
        } catch {
            print("Failed to fetch test users: \(error)")
            await MainActor.run {
                self.testUsers = getDefaultUsers()
                isLoading = false
            }
        }
    }
    
    private func getDefaultUsers() -> [TestUser] {
        return []
    }

    func saveJournalEntry(_ entry: JournalEntry) async -> Bool {
        await MainActor.run { isLoading = true }
        
        do {
            guard let session = supabase.auth.currentSession else {
                await MainActor.run { isLoading = false }
                return false
            }
            
            _ = try await JournalService.shared.saveJournalEntry(
                description: entry.entryText,
                testUserId: Int32(entry.userId),
                supervisorUid: session.user.id,
                appName: entry.appName
            )
            
            await MainActor.run { isLoading = false }
            return true
        } catch {
            print("Failed to save journal entry: \(error)")
            await MainActor.run { isLoading = false }
            return false
        }
    }
    
    func fetchJournalEntries() async -> [JournalEntry] {
        await MainActor.run { isLoading = true }
        
        do {
            let journals = try await JournalService.shared.fetchJournalEntries()
            await MainActor.run { isLoading = false }
            
            return journals.compactMap { journal in
                if let description = journal.description,
                   let testUserId = journal.testUserId {
                    let user = testUsers.first { $0.id == testUserId }
                    return JournalEntry(
                        id: UUID(),
                        date: journal.createdAt,
                        appName: journal.appName ?? "Unknown App",
                        userName: user?.fullName ?? "Unknown User",
                        userId: Int(testUserId),
                        entryText: description
                    )
                } else {
                    return nil
                }
            }
        } catch {
            print("Failed to fetch journal entries: \(error)")
            await MainActor.run { isLoading = false }
            return []
        }
    }
    
    private func loadDefaultData() {
        Task {
            await fetchApps()
            await fetchTestUsers()
        }
    }
}




