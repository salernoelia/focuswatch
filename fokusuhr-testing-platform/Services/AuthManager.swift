import Foundation
import Combine
import SwiftUI
import Supabase
#if os(iOS)
import WatchConnectivity
#endif

class AuthManager: ObservableObject {
    @Published var isLoggedIn = false
    @Published var currentUserEmail: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    static let shared = AuthManager()
    
    private init() {
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        if let session = supabase.auth.currentSession {
            isLoggedIn = true
            currentUserEmail = session.user.email ?? ""
            Task {
                await SupervisorManager.shared.fetchCurrentSupervisor()
            }
        } else {
            isLoggedIn = false
            currentUserEmail = ""
        }
    }
    
    func signIn(email: String, password: String) async -> Bool {
        await MainActor.run { 
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            await MainActor.run {
                isLoggedIn = true
                currentUserEmail = session.user.email ?? ""
                isLoading = false
            }
            
            await SupervisorManager.shared.fetchCurrentSupervisor()
            
            saveAuthTokens(session: session)
            syncAuthToWatch(session: session)
            
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
            try await supabase.auth.signOut()
            await MainActor.run {
                isLoggedIn = false
                currentUserEmail = ""
                isLoading = false
            }
            clearAuthTokens()
            syncAuthToWatch(session: nil)
        } catch {
            await MainActor.run { isLoading = false }
        }
    }
    
    private func saveAuthTokens(session: Session) {
        UserDefaults.standard.set(session.accessToken, forKey: AppConstants.StorageKeys.authToken)
        UserDefaults.standard.set(session.refreshToken, forKey: AppConstants.StorageKeys.refreshToken)
    }
    
    private func clearAuthTokens() {
        UserDefaults.standard.removeObject(forKey: AppConstants.StorageKeys.authToken)
        UserDefaults.standard.removeObject(forKey: AppConstants.StorageKeys.refreshToken)
    }
    
    #if os(iOS)
    private func syncAuthToWatch(session: Session?) {
        guard WCSession.isSupported() else { return }
        guard WCSession.default.activationState == .activated else { return }
        guard WCSession.default.isReachable else { return }
        
        var message: [String: Any] = ["action": "updateAuth"]
        
        if let session = session {
            message["accessToken"] = session.accessToken
            message["refreshToken"] = session.refreshToken
            message["isLoggedIn"] = true
        } else {
            message["isLoggedIn"] = false
        }
        
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            #if DEBUG
            print("Failed to sync auth to watch: \(error.localizedDescription)")
            #endif
        }
    }
    #else
    private func syncAuthToWatch(session: Session?) {
    }
    #endif
    
    func getAccessToken() -> String? {
        return supabase.auth.currentSession?.accessToken
    }
}
