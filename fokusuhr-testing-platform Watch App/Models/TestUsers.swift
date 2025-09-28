import Foundation

typealias TestUser = PublicSchema.TestUsersSelect

extension TestUser: Identifiable {
    var fullName: String {
        "\(firstName) \(lastName)"
    }
}

func fetchTestUsers() async -> [TestUser] {
    do {
        let testUsers: [TestUser] = try await supabase
            .from("test_users")
            .select()
            .execute()
            .value
        print(testUsers)
        return testUsers
    } catch {
        print("Error fetching test users: \(error)")
        return []
    }
}