import Foundation
import SwiftUI

class FeedbackManager: ObservableObject {
  @Published var isLoading = false
  @Published var lastError: AppError?

  static let shared = FeedbackManager()

  func sendFeedback(
    appName: String?,
    description: String?,
    implemented: Bool? = nil
  ) async -> Bool {
    await MainActor.run {
      isLoading = true
      lastError = nil
    }

    let feedbackInsert = PublicSchema.FeedbackInsert(
      appName: appName,
      createdAt: nil,
      description: description,
      id: nil,
      implemented: implemented
    )

    do {
      try await supabase
        .from("feedback")
        .insert(feedbackInsert)
        .execute()

      await MainActor.run { isLoading = false }
      return true
    } catch {
      let appError = AppError.databaseQueryFailed(
        operation: "send feedback", underlying: error)
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
}
