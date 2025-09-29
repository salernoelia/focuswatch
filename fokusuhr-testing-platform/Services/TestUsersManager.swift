import Foundation
import PostgREST
import Combine
import SwiftUI

typealias TestUser = PublicSchema.TestUsersSelect

extension TestUser: Identifiable {
    var fullName: String {
        "\(firstName) \(lastName)"
    }
}

class TestUsersManager: ObservableObject {
    @Published var testUsers: [TestUser] = []
    @Published var selectedUserId: Int32?
    @Published var isLoading = false
    
    static let shared = TestUsersManager()
    
    // Special ID for "No Testuser" option
    static let noTestUserID: Int32 = -1
    
    var selectedUser: TestUser? {
        guard let selectedUserId = selectedUserId, selectedUserId != Self.noTestUserID else { return nil }
        return testUsers.first { $0.id == selectedUserId }
    }
    
    var isNoTestUserSelected: Bool {
        selectedUserId == Self.noTestUserID
    }
    
    // All available options including "No Testuser"
    var allUserOptions: [UserOption] {
        var options = [UserOption(id: Self.noTestUserID, displayName: "No Testuser (Supervisor Entry)", isSpecial: true)]
        options.append(contentsOf: testUsers.map { UserOption(id: $0.id, displayName: $0.fullName, isSpecial: false) })
        return options
    }
    
    private init() {
        Task {
            await fetchTestUsers()
        }
    }
    
    func fetchTestUsers() async {
        await MainActor.run { isLoading = true }
        
        do {
            let users: [TestUser] = try await supabase
                .from("test_users")
                .select()
                .execute()
                .value
            
            await MainActor.run {
                testUsers = users
                if selectedUserId == nil {
                    selectedUserId = testUsers.first?.id
                }
                isLoading = false
            }
            
        } catch {
            print("Error fetching test users: \(error)")
            await MainActor.run {
                testUsers = []
                isLoading = false
            }
        }
    }
    
    func addTestUser(_ user: PublicSchema.TestUsersInsert) async {
        await MainActor.run { isLoading = true }
        
        do {
            let newUser: TestUser = try await supabase
                .from("test_users")
                .insert(user)
                .select()
                .single()
                .execute()
                .value
            
            await MainActor.run {
                testUsers.append(newUser)
                if selectedUserId == nil {
                    selectedUserId = newUser.id
                }
                isLoading = false
            }
        } catch {
            print("Error adding test user: \(error)")
            await MainActor.run { isLoading = false }
        }
    }
    
    func deleteTestUser(_ user: TestUser) async {
        await MainActor.run { isLoading = true }
        
        do {
            try await supabase
                .from("test_users")
                .delete()
                .eq("id", value: user.id as! PostgrestFilterValue)
                .execute()
            
            await MainActor.run {
                testUsers.removeAll { $0.id == user.id }
                if selectedUserId == user.id {
                    selectedUserId = testUsers.first?.id
                }
                isLoading = false
            }
        } catch {
            print("Error deleting test user: \(error)")
            await MainActor.run { isLoading = false }
        }
    }
    
    func selectUser(_ userId: Int32?) {
        selectedUserId = userId
    }
}





