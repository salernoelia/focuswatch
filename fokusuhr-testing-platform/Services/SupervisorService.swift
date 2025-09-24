//
//  SupervisorService.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 24.09.2025.
//

import Foundation

class SupervisorService {
    static let shared = SupervisorService()
    
    private init() {}
    
    func fetchSupervisors() async throws -> [Supervisor] {
        let response: [Supervisor] = try await supabase
            .from("supervisors")
            .select()
            .eq("status", value: "active")
            .execute()
            .value
        return response
    }
    
    func createSupervisor(firstName: String, lastName: String, email: String) async throws -> Supervisor {
        let supervisor: Supervisor = try await supabase
            .from("supervisors")
            .insert([
                "first_name": firstName,
                "last_name": lastName,
                "email": email,
                "status": "pending",
                "uid": UUID().uuidString
            ])
            .select()
            .single()
            .execute()
            .value
        return supervisor
    }
    
    func deleteSupervisor(uid: UUID) async throws {
        try await supabase
            .from("supervisors")
            .delete()
            .eq("uid", value: uid.uuidString)
            .execute()
    }
}