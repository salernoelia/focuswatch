import Combine
import Foundation
import SwiftUI

class JournalManager: ObservableObject {
  @Published var isLoading = false
  @Published var lastError: AppError?

  static let shared = JournalManager()

  func saveJournalEntry(
    appName: String,
    description: String,
    testUserId: Int32?
  ) async -> Bool {
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

      let journalInsert = PublicSchema.JournalsInsert(
        appId: nil,
        appName: appName,
        createdAt: nil,
        description: description,
        id: nil,
        supervisorUid: session.user.id,
        testUserId: testUserId == TestUsersManager.noTestUserID ? nil : testUserId
      )

      try await supabase
        .from("journals")
        .insert(journalInsert)
        .execute()

      await MainActor.run { isLoading = false }
      return true
    } catch {
      let appError = AppError.databaseQueryFailed(
        operation: "save journal entry", underlying: error)
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

  func fetchJournalEntries() async -> [PublicSchema.JournalsSelect] {
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

      let journals: [PublicSchema.JournalsSelect] =
        try await supabase
        .from("journals")
        .select()
        .eq("supervisor_uid", value: session.user.id)
        .execute()
        .value

      await MainActor.run { isLoading = false }
      return journals
    } catch {
      let appError = AppError.databaseQueryFailed(
        operation: "fetch journal entries", underlying: error)
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
