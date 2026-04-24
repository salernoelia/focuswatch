import Combine
import Foundation
import PostgREST
import Supabase
import SwiftUI

typealias TestUser = PublicSchema.TestUsersSelect

struct UserOption: Identifiable {
    let id: Int32
    let displayName: String
    let isSpecial: Bool
}

extension TestUser: Identifiable {
    var fullName: String {
        "\(firstName) \(lastName)"
    }
}

class TestUsersManager: ObservableObject {
    @Published var testUsers: [TestUser] = []
    @Published var selectedUserId: Int32?
    @Published var isLoading = false
    @Published var lastError: AppError?
    
    static let shared = TestUsersManager()
    
    static let noTestUserID: Int32 = AppConstants.TestUser.noTestUserID
    
    var selectedUser: TestUser? {
        guard let selectedUserId = selectedUserId, selectedUserId != Self.noTestUserID else { return nil }
        return testUsers.first { $0.id == selectedUserId }
    }
    
    var isNoTestUserSelected: Bool {
        selectedUserId == Self.noTestUserID
    }
    

    var allUserOptions: [UserOption] {
        var options = [UserOption(
            id: Self.noTestUserID, 
            displayName: AppConstants.TestUser.noTestUserDisplayName, 
            isSpecial: true
        )]
        options.append(contentsOf: testUsers.map { 
            UserOption(id: $0.id, displayName: $0.fullName, isSpecial: false) 
        })
        return options
    }
    
    private init() {
        Task {
            await fetchTestUsers()
        }
    }
    
    func fetchTestUsers() async {
        await MainActor.run { 
            isLoading = true
            lastError = nil
        }
        
        do {
            let users: [TestUser] = try await supabase
                .from("test_users")
                .select()
                .execute()
                .value
            
            await MainActor.run {
                testUsers = users
                if selectedUserId == nil {
                    selectedUserId = Self.noTestUserID
                }
                isLoading = false
            }
            
        } catch {
            let appError = AppError.databaseQueryFailed(operation: "fetch test users", underlying: error)
            #if DEBUG
            ErrorLogger.log(appError)
            #endif
            
            await MainActor.run {
                testUsers = []
                isLoading = false
                lastError = appError
            }
        }
    }
    
    func addTestUser(_ user: PublicSchema.TestUsersInsert) async {
        await MainActor.run { 
            isLoading = true
            lastError = nil
        }
        
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
                    selectedUserId = Self.noTestUserID
                }
                isLoading = false
            }
        } catch {
            let appError = AppError.databaseQueryFailed(operation: "add test user", underlying: error)
            #if DEBUG
            ErrorLogger.log(appError)
            #endif
            
            await MainActor.run { 
                isLoading = false
                lastError = appError
            }
        }
    }
    
    func deleteTestUser(_ user: TestUser) async {
        await MainActor.run { 
            isLoading = true
            lastError = nil
        }
        
        do {
            guard let filterValue = user.id as? PostgrestFilterValue else {
                throw AppError.invalidData(reason: "User ID cannot be used as filter value")
            }
            
            try await supabase
                .from("test_users")
                .delete()
                .eq("id", value: filterValue)
                .execute()
            
            await MainActor.run {
                testUsers.removeAll { $0.id == user.id }
                if selectedUserId == user.id {
                    selectedUserId = Self.noTestUserID
                }
                isLoading = false
            }
        } catch {
            let appError: AppError
            if let error = error as? AppError {
                appError = error
            } else {
                appError = AppError.databaseQueryFailed(operation: "delete test user", underlying: error)
            }
            
            #if DEBUG
            ErrorLogger.log(appError)
            #endif
            
            await MainActor.run { 
                isLoading = false
                lastError = appError
            }
        }
    }
    
    func selectUser(_ userId: Int32?) {
        selectedUserId = userId
    }
}





