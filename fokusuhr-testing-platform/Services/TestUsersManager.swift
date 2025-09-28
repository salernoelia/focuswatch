import Foundation
import Combine
import SwiftUI

class TestUsersManager: ObservableObject {
    @Published var testUsers: [TestUser] = []
    @Published var supervisors: [Supervisor] = []
    @Published var selectedUserId: Int?
    @Published var isLoading = false
    
    static let shared = TestUsersManager()
    
    var selectedUser: TestUser? {
        guard let selectedUserId = selectedUserId else { return nil }
        return testUsers.first { $0.id == selectedUserId }
    }
    
    private init() {
        Task {
            await fetchTestUsers()
            await fetchSupervisors()
        }
    }
    
    func fetchTestUsers() async {
        await MainActor.run { isLoading = true }
        

        
        await MainActor.run {
            testUsers = getDefaultUsers()
            if selectedUserId == nil {
                selectedUserId = testUsers.first?.id
            }
            isLoading = false
        }
    }
    
    func fetchSupervisors() async {
        await MainActor.run { isLoading = true }
        

        
        await MainActor.run {
            supervisors = getDefaultSupervisors()
            isLoading = false
        }
    }
    
    func addTestUser(_ user: TestUser) async {
        await MainActor.run { isLoading = true }
        

        
        await MainActor.run {
            testUsers.append(user)
            if selectedUserId == nil {
                selectedUserId = user.id
            }
            isLoading = false
        }
    }
    
    func deleteTestUser(_ user: TestUser) async {
        await MainActor.run { isLoading = true }
        

        
        await MainActor.run {
            testUsers.removeAll { $0.id == user.id }
            if selectedUserId == user.id {
                selectedUserId = testUsers.first?.id
            }
            isLoading = false
        }
    }
    
    func addSupervisor(_ supervisor: Supervisor) async {
        await MainActor.run { isLoading = true }
        
      
        
        await MainActor.run {
            supervisors.append(supervisor)
            isLoading = false
        }
    }
    
    func deleteSupervisor(_ supervisor: Supervisor) async {
        await MainActor.run { isLoading = true }
        

        
        await MainActor.run {
            supervisors.removeAll { $0.uid == supervisor.uid }
            isLoading = false
        }
    }
    
    func selectUser(_ userId: Int?) {
        selectedUserId = userId
    }
    
    private func getDefaultUsers() -> [TestUser] {
        return [
            TestUser(id: 1, first_name: "Jon", last_name: "Doe", age: 29, supervisor_uid: "1"),
            TestUser(id: 2, first_name: "Lina", last_name: "Wong", age: 34, supervisor_uid: "2"),
            TestUser(id: 3, first_name: "Alex", last_name: "Smith", age: 26, supervisor_uid: "1"),
            TestUser(id: 4, first_name: "Sarah", last_name: "Johnson", age: 31, supervisor_uid: "2"),
            TestUser(id: 5, first_name: "Mike", last_name: "Chen", age: 28, supervisor_uid: "1")
        ]
    }
    
    private func getDefaultSupervisors() -> [Supervisor] {
        return [
            Supervisor(uid: "1", first_name: "Ari", last_name: "Kato"),
            Supervisor(uid: "2", first_name: "Maya", last_name: "Perez")
        ]
    }
}




