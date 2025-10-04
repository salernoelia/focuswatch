import Foundation
import Combine
import SwiftUI

typealias Supervisor = PublicSchema.SupervisorsSelect

extension Supervisor {
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var id: String { uid.uuidString }
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
            
            let supervisors: [Supervisor] = try await supabase
                .from("supervisors")
                .select()
                .eq("uid", value: session.user.id)
                .execute()
                .value
            
            await MainActor.run {
                currentSupervisor = supervisors.first
                isLoading = false
            }
            
            #if DEBUG
            if supervisors.isEmpty {
                print("Warning: No supervisor found for user ID: \(session.user.id)")
            } else if supervisors.count > 1 {
                print("Warning: Multiple supervisors found for user ID: \(session.user.id), using first one")
            }
            #endif
        } catch {
            let appError = AppError.databaseQueryFailed(operation: "fetch supervisor", underlying: error)
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