import Auth
import Combine
import Foundation
import PostgREST
import Supabase
import SwiftUI

typealias Supervisor = PublicSchema.UserProfilesSelect

extension Supervisor {
    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var id: String { userId.uuidString }
}

class SupervisorManager: ObservableObject {
    @Published var currentSupervisor: Supervisor?
    @Published var isLoading = false
    @Published var lastError: AppError?

    static let shared = SupervisorManager()

    private init() {
        Task {
            await fetchCurrentSupervisor()
        }
    }

    func fetchCurrentSupervisor() async {
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
                    currentSupervisor = nil
                    isLoading = false
                    lastError = error
                }
                return
            }

            let profiles: [Supervisor] = try await supabase
                .from("user_profiles")
                .select()
                .eq("user_id", value: session.user.id)
                .execute()
                .value

            await MainActor.run {
                currentSupervisor = profiles.first
                isLoading = false
            }

            #if DEBUG
                if profiles.isEmpty {
                    print("Warning: No user profile found for user ID: \(session.user.id)")
                } else if profiles.count > 1 {
                    print("Warning: Multiple user profiles found for user ID: \(session.user.id), using first one")
                }
            #endif
        } catch {
            let appError = AppError.databaseQueryFailed(operation: "fetch user profile", underlying: error)
            #if DEBUG
                ErrorLogger.log(appError)
            #endif

            await MainActor.run {
                currentSupervisor = nil
                isLoading = false
                lastError = appError
            }
        }
    }
}
