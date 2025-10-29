import Foundation
import Supabase

class AuthManager: ObservableObject {
    @Published var isLoggedIn = false
    
    static let shared = AuthManager()
    
    private var client: SupabaseClient = SupabaseClient(
        supabaseURL: SupabaseConfig.url,
        supabaseKey: SupabaseConfig.anonKey
    )
    
    private init() {
        loadAuthState()
    }
    
    func updateAuthState(accessToken: String?, refreshToken: String?) {
        if let accessToken = accessToken, let refreshToken = refreshToken {
            UserDefaults.standard.set(accessToken, forKey: AppConstants.StorageKeys.authToken)
            UserDefaults.standard.set(refreshToken, forKey: AppConstants.StorageKeys.refreshToken)
            isLoggedIn = true
            initializeClient(accessToken: accessToken, refreshToken: refreshToken)
        } else {
            clearAuthState()
        }
    }
    
    func clearAuthState() {
        UserDefaults.standard.removeObject(forKey: AppConstants.StorageKeys.authToken)
        UserDefaults.standard.removeObject(forKey: AppConstants.StorageKeys.refreshToken)
        isLoggedIn = false
        Task {
            try? await client.auth.signOut()
        }
    }
    
    private func loadAuthState() {
        guard let accessToken = UserDefaults.standard.string(forKey: AppConstants.StorageKeys.authToken),
              let refreshToken = UserDefaults.standard.string(forKey: AppConstants.StorageKeys.refreshToken) else {
            isLoggedIn = false
            return
        }
        
        isLoggedIn = true
        initializeClient(accessToken: accessToken, refreshToken: refreshToken)
    }
    
    private func initializeClient(accessToken: String, refreshToken: String) {
        Task {
            do {
                try await client.auth.setSession(accessToken: accessToken, refreshToken: refreshToken)
            } catch {
                #if DEBUG
                print("Failed to restore session: \(error.localizedDescription)")
                #endif
                await MainActor.run {
                    self.clearAuthState()
                }
            }
        }
    }
    
    func getClient() -> SupabaseClient {
        return client
    }
    
    func getAccessToken() -> String? {
        return UserDefaults.standard.string(forKey: AppConstants.StorageKeys.authToken)
    }
}
