//
//  AuthService.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 24.09.2025.
//

import Foundation
import SwiftUI

class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isLoggedIn = false
    @Published var currentUserEmail = ""
    
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
    
    func signIn(email: String, password: String) async throws {
        let response = try await supabase.auth.signIn(
            email: email,
            password: password
        )
        
        await MainActor.run {
            if response.user != nil {
                isLoggedIn = true
                currentUserEmail = response.user.email ?? ""
            }
        }
    }
    
    func signOut() async throws {
        try await supabase.auth.signOut()
        
        await MainActor.run {
            isLoggedIn = false
            currentUserEmail = ""
        }
    }
}