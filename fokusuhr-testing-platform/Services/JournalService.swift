//
//  JournalService.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 24.09.2025.
//

import Foundation

class JournalService {
    static let shared = JournalService()
    
    private init() {}
    
    func saveJournalEntry(description: String, testUserId: Int32, supervisorUid: UUID, appName: String) async throws -> Journal {
        let journal: Journal = try await supabase
            .from("journals")
            .insert([
                "description": description,
                "test_user_id": String(testUserId),
                "supervisor_uid": supervisorUid.uuidString,
                "app_name": appName
            ])
            .select()
            .single()
            .execute()
            .value
        return journal
    }
    
    func fetchJournalEntries() async throws -> [Journal] {
        let response: [Journal] = try await supabase
            .from("journals")
            .select()
            .order("id", ascending: false)
            .execute()
            .value
        return response
    }
}
