//
//  TestUsers.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 07.09.2025.
//

struct TestUser: Identifiable, Codable {
    let id: Int
    var first_name: String
    var last_name: String
    var age: Int
    var supervisor_uid: String
    
    var fullName: String {
        "\(first_name) \(last_name)"
    }
}

func fetchTestUsers() async {
    do {
        let testUsers: [TestUser] = try await supabase
            .from("test_users")
            .select()
            .execute()
            .value
        print(testUsers)
    } catch {
        print("Error fetching test users: \(error)")
    }
}
