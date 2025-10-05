import Foundation
import Combine
import SwiftUI
import Supabase
import Auth

class AuthManager: ObservableObject {
    @Published var isLoggedIn = false
    @Published var currentUserEmail: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    static let shared = AuthManager()
    
    private let supabaseClient: SupabaseClient
    
    init(supabaseClient: SupabaseClient = supabase) {
        self.supabaseClient = supabaseClient
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        if let sessionData = SharedAuthStorage.loadSession() {
            loadSessionFromStorage(sessionData)
            print(sessionData)
        } else if let session = supabaseClient.auth.currentSession {
            applySession(session)
            print(session)
        } else {
            clearAuthState()
        }
    }
    
    private func loadSessionFromStorage(_ sessionData: Data) {
        do {
            let session = try JSONDecoder().decode(Session.self, from: sessionData)
            Task {
                try? await supabaseClient.auth.setSession(accessToken: session.accessToken, refreshToken: session.refreshToken)
                await MainActor.run {
                    self.applySession(session)
                }
            }
        } catch {
            #if DEBUG
            ErrorLogger.log(AppError.decodingFailed(type: "auth session", underlying: error))
            #endif
            clearAuthState()
        }
    }
    
    private func applySession(_ session: Session) {
        isLoggedIn = true
        currentUserEmail = session.user.email ?? ""
        
        #if os(iOS)
        Task {
            await SupervisorManager.shared.fetchCurrentSupervisor()
        }
        #endif
    }
    
    private func clearAuthState() {
        isLoggedIn = false
        currentUserEmail = ""
    }
    
    func signIn(email: String, password: String) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let session = try await supabaseClient.auth.signIn(
                email: email,
                password: password
            )
            
            let sessionData = try JSONEncoder().encode(session)
            SharedAuthStorage.saveSession(sessionData)
            
            await MainActor.run {
                applySession(session)
                isLoading = false
            }
            
            return true
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
            return false
        }
    }
    
    func signOut() async {
        await MainActor.run { isLoading = true }
        
        do {
            try await supabaseClient.auth.signOut()
            SharedAuthStorage.clearSession()
            
            await MainActor.run {
                clearAuthState()
                isLoading = false
            }
        } catch {
            await MainActor.run { isLoading = false }
        }
    }
}
