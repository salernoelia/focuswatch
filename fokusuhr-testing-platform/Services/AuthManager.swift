import Foundation
import Combine
import SwiftUI

class AuthManager: ObservableObject {
    @Published var isLoggedIn = false
    @Published var currentUserEmail: String = ""
    @Published var isLoading = false
    
    static let shared = AuthManager()
    
    private init() {
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        if let session = supabase.auth.currentSession {
            isLoggedIn = true
            currentUserEmail = session.user.email ?? ""
        } else {
            isLoggedIn = false
            currentUserEmail = ""
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
        } catch {
            await MainActor.run { isLoading = false }
        }
    }
}