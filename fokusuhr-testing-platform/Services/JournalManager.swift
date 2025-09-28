import Foundation
import Combine
import SwiftUI

struct JournalEntry: Identifiable, Codable {
    var id = UUID()
    var date = Date()
    var appName: String
    var userName: String
    var userId: Int32
    var entryText: String
}

class JournalManager: ObservableObject {
    @Published var isLoading = false
    
    static let shared = JournalManager()

    func saveJournalEntry(_ entry: JournalEntry) async -> Bool {
        await MainActor.run { isLoading = true }
        
        do {
            guard let session = supabase.auth.currentSession else {
                await MainActor.run { isLoading = false }
                return false
            }
            
            let journalInsert = PublicSchema.JournalsInsert(
                appId: nil,
                appName: entry.appName,
                createdAt: nil,
                description: entry.entryText,
                id: nil,
                supervisorUid: session.user.id,
                testUserId: entry.userId
            )
            
            try await supabase
                .from("journals")
                .insert(journalInsert)
                .execute()
            
            await MainActor.run { isLoading = false }
            return true
        } catch {
            print("Error saving journal entry: \(error)")
            await MainActor.run { isLoading = false }
            return false
        }
    }
    
    func fetchJournalEntries() async -> [JournalEntry] {
        await MainActor.run { isLoading = true }
        
        do {
            guard let session = supabase.auth.currentSession else {
                await MainActor.run { isLoading = false }
                return []
            }
            
            let journals: [PublicSchema.JournalsSelect] = try await supabase
                .from("journals")
                .select()
                .eq("supervisor_uid", value: session.user.id)
                .execute()
                .value
            
            let testUsers: [TestUser] = try await supabase
                .from("test_users")
                .select()
                .execute()
                .value
            
            let entries = journals.compactMap { journal -> JournalEntry? in
                guard let userId = journal.testUserId,
                      let appName = journal.appName,
                      let description = journal.description else { return nil }
                
                let user = testUsers.first { $0.id == userId }
                let userName = user?.fullName ?? "Unknown User"
                
                let createdDate = journal.createdAt.flatMap { ISO8601DateFormatter().date(from: $0) } ?? Date()
                
                return JournalEntry(
                    date: createdDate,
                    appName: appName,
                    userName: userName,
                    userId: userId,
                    entryText: description
                )
            }
            
            await MainActor.run { isLoading = false }
            return entries
        } catch {
            print("Error fetching journal entries: \(error)")
            await MainActor.run { isLoading = false }
            return []
        }
    }
}




