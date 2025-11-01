import SwiftUI
import Combine

class SettingsViewModel: ObservableObject {
  // MARK: - Published Properties
  
  @Published var searchText = ""
  @Published var showingAddUser = false
  @Published var showingLogin = false
  @Published private(set) var watchUUID = ""
  
  // MARK: - Managers
  
  private let authManager = AuthManager.shared
  private let telemetryManager = TelemetryManager.shared
  private let testUsersManager = TestUsersManager.shared
  private let supervisorManager = SupervisorManager.shared
  private let watchConfig = WatchConfig.shared
  private var cancellables = Set<AnyCancellable>()
  
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
  
  init() {
    loadWatchUUID()
    observeWatchUUIDChanges()
  }
  
  private func loadWatchUUID() {
    watchUUID = watchConfig.uuid
    #if DEBUG
      print("📱 SettingsViewModel: Loaded Watch UUID: \(watchUUID)")
    #endif
  }
  
  private func observeWatchUUIDChanges() {
    NotificationCenter.default.publisher(
      for: WatchConfig.watchUUIDDidChangeNotification
    )
    .receive(on: DispatchQueue.main)
    .sink { [weak self] notification in
      #if DEBUG
        print("📱 SettingsViewModel: Received Watch UUID change notification")
      #endif
      self?.loadWatchUUID()
    }
    .store(in: &cancellables)
    
    NotificationCenter.default.publisher(
      for: UserDefaults.didChangeNotification
    )
    .receive(on: DispatchQueue.main)
    .sink { [weak self] _ in
      self?.loadWatchUUID()
    }
    .store(in: &cancellables)
  }
  
  // MARK: - Methods
  
  func signOut() async {
    await authManager.signOut()
  }
  
  func refresh() async {
    loadWatchUUID()
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
