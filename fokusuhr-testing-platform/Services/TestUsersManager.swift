import Foundation
import Combine
import SwiftUI

class TestUsersManager: ObservableObject {
    
    @Published var testUsers: [TestUser] = []
    @Published var isLoading = false
    
    static let shared = TestUsersManager()
    
    private init() {
        Task {
            
            await fetchTestUsers()
        }
    }
    


    func fetchTestUsers() async {
        await MainActor.run { isLoading = true }
        
        // TODO: Replace with Supabase API call & refactor into own model class
        await MainActor.run {
            testUsers = getDefaultUsers()
            isLoading = false
        }
    }
    
    private func getDefaultUsers() -> [TestUser] {
        return [
            TestUser(id: 1, first_name: "Jon", last_name: "Doe", age: 29, supervisor_uid: "1"),
            TestUser(id: 2, first_name: "Lina", last_name: "Wong", age: 34, supervisor_uid: "2"),
            TestUser(id: 3, first_name: "Alex", last_name: "Smith", age: 26, supervisor_uid: "1")
        ]
    }

   
}




