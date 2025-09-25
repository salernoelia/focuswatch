//
//  JournalManager.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 25.09.2025.
//

import Foundation
import Combine
import SwiftUI


class JournalManager: ObservableObject {
    @Published var isLoading = false
    
    static let shared = JournalManager()


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
    
   
}




