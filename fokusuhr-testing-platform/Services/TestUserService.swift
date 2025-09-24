//
//  TestUserService.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 24.09.2025.
//

import Foundation

class TestUserService {
    static let shared = TestUserService()
    
    private init() {}
    
    func fetchTestUsers() async throws -> [TestUser] {
        let response: [TestUser] = try await supabase
            .from("test_users")
            .select()
            .execute()
            .value
        return response
    }
    
    func createTestUser(firstName: String, lastName: String, age: Int, gender: PublicSchema.Genders?, supervisorUid: UUID) async throws -> TestUser {
        let testUser: TestUser = try await supabase
            .from("test_users")
            .insert([
                "first_name": firstName,
                "last_name": lastName,
                "age": String(age),
                "gender": gender?.rawValue,
                "supervisor_uid": supervisorUid.uuidString
            ])
            .select()
            .single()
            .execute()
            .value
        return testUser
    }
    
    func deleteTestUser(id: Int32) async throws {
        try await supabase
            .from("test_users")
            .delete()
            .eq("id", value: String(id))
            .execute()
    }
}
