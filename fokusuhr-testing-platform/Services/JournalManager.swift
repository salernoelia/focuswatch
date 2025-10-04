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
    @Published var lastError: AppError?
    
    static let shared = JournalManager()

    func saveJournalEntry(_ entry: JournalEntry) async -> Bool {
        await MainActor.run { 
            isLoading = true
            lastError = nil
        }
        
        do {
            guard let session = supabase.auth.currentSession else {
                let error = AppError.noActiveSession
                #if DEBUG
                ErrorLogger.log(error)
                #endif
                await MainActor.run { 
                    isLoading = false
                    lastError = error
                }
                return false
            }
            
            let journalInsert: PublicSchema.JournalsInsert
            

            if entry.userId == TestUsersManager.noTestUserID {
                journalInsert = PublicSchema.JournalsInsert(
                    appId: nil,
                    appName: entry.appName,
                    createdAt: nil,
                    description: entry.entryText,
                    id: nil,
                    supervisorUid: session.user.id,
                    testUserId: nil 
                )
            } else {
                journalInsert = PublicSchema.JournalsInsert(
                    appId: nil,
                    appName: entry.appName,
                    createdAt: nil,
                    description: entry.entryText,
                    id: nil,
                    supervisorUid: session.user.id,
                    testUserId: entry.userId
                )
            }
            
            try await supabase
                .from("journals")
                .insert(journalInsert)
                .execute()
            
            await MainActor.run { isLoading = false }
            return true
        } catch {
            let appError = AppError.databaseQueryFailed(operation: "save journal entry", underlying: error)
            #if DEBUG
            ErrorLogger.log(appError)
            #endif
            
            await MainActor.run { 
                isLoading = false
                lastError = appError
            }
            return false
        }
    }
    
    func fetchJournalEntries() async -> [JournalEntry] {
        await MainActor.run { 
            isLoading = true
            lastError = nil
        }
        
        do {
            guard let session = supabase.auth.currentSession else {
                let error = AppError.noActiveSession
                #if DEBUG
                ErrorLogger.log(error)
                #endif
                await MainActor.run { 
                    isLoading = false
                    lastError = error
                }
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
            
            let supervisors: [Supervisor] = try await supabase
                .from("supervisors")
                .select()
                .eq("uid", value: session.user.id)
                .execute()
                .value
            
            let currentSupervisor = supervisors.first
            
            let entries = journals.compactMap { journal -> JournalEntry? in
                guard let appName = journal.appName,
                      let description = journal.description else { return nil }
                
                let createdDate = journal.createdAt.flatMap { ISO8601DateFormatter().date(from: $0) } ?? Date()
                

                if journal.testUserId == nil {
                    let supervisorName = currentSupervisor?.fullName ?? "Supervisor"
                    return JournalEntry(
                        date: createdDate,
                        appName: appName,
                        userName: supervisorName,
                        userId: TestUsersManager.noTestUserID,
                        entryText: description
                    )
                } else if let userId = journal.testUserId {

                    let user = testUsers.first { $0.id == userId }
                    let userName = user?.fullName ?? "Unknown User"
                    
                    return JournalEntry(
                        date: createdDate,
                        appName: appName,
                        userName: userName,
                        userId: userId,
                        entryText: description
                    )
                }
                
                return nil
            }
            
            await MainActor.run { isLoading = false }
            return entries
        } catch {
            let appError = AppError.databaseQueryFailed(operation: "fetch journal entries", underlying: error)
            #if DEBUG
            ErrorLogger.log(appError)
            #endif
            
            await MainActor.run { 
                isLoading = false
                lastError = appError
            }
            return []
        }
    }
}




