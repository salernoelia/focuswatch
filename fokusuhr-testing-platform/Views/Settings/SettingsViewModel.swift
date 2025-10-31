import SwiftUI
import Combine

class SettingsViewModel: ObservableObject {
  // MARK: - Published Properties
  
  @Published var searchText = ""
  @Published var showingAddUser = false
  @Published var showingLogin = false
  
  // MARK: - Managers
  
  private let authManager = AuthManager.shared
  private let telemetryManager = TelemetryManager.shared
  private let testUsersManager = TestUsersManager.shared
  private let supervisorManager = SupervisorManager.shared
  private let watchConfig = WatchConfig.shared
  
  // MARK: - Computed Properties
  
  var isLoggedIn: Bool {
    authManager.isLoggedIn
  }
  
  var currentUserEmail: String {
    authManager.currentUserEmail
  }
  
  var isLoading: Bool {
    authManager.isLoading || testUsersManager.isLoading
  }
  
  var hasTelemetryConsent: Binding<Bool> {
    Binding(
      get: { self.telemetryManager.hasConsent },
      set: { self.telemetryManager.hasConsent = $0 }
    )
  }
  
  var filteredUsers: [TestUser] {
    if searchText.isEmpty {
      return testUsersManager.testUsers
    }
    return testUsersManager.testUsers.filter { user in
      user.fullName.localizedCaseInsensitiveContains(searchText)
    }
  }
  
  var testUsers: [TestUser] {
    testUsersManager.testUsers
  }
  
  var selectedUser: TestUser? {
    testUsersManager.selectedUser
  }
  
  var currentSupervisor: Supervisor? {
    supervisorManager.currentSupervisor
  }
  
  var watchUUID: String {
    watchConfig.uuid
  }
  
  // MARK: - Methods
  
  func signOut() async {
    await authManager.signOut()
  }
  
  func refresh() async {
    await supervisorManager.fetchCurrentSupervisor()
    await testUsersManager.fetchTestUsers()
  }
  
  func addTestUser(_ user: PublicSchema.TestUsersInsert) async {
    await testUsersManager.addTestUser(user)
  }
  
  func checkAuthStatus() {
    authManager.checkAuthStatus()
  }
  
  func selectUser(_ userId: Int32?) {
    testUsersManager.selectUser(userId)
  }
}
