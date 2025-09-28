import Foundation
import Combine
import SwiftUI

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
            let response = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            await MainActor.run {
                if response.user != nil {
                    isLoggedIn = true
                    currentUserEmail = response.user.email ?? ""
                    isLoading = false
                    return
                }
                errorMessage = "Login failed. Please check your credentials."
                isLoading = false
            }
            return response.user != nil
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
        } catch {
            await MainActor.run { isLoading = false }
        }
    }
}