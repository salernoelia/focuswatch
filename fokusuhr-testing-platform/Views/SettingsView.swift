import SwiftUI

struct SettingsView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var testUsersManager = TestUsersManager.shared
    @State private var showingAddSupervisor = false
    @State private var showingAddUser = false
    @State private var showingLogin = false
    @State private var searchText = ""
    
    private var filteredUsers: [TestUser] {
        if searchText.isEmpty {
            return testUsersManager.testUsers
        }
        return testUsersManager.testUsers.filter { user in
            user.fullName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section("Authentication") {
                    if authManager.isLoggedIn {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Logged in as:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(authManager.currentUserEmail)
                                .font(.body)
                        }
                        
                        Button("Sign Out") {
                            Task {
                                await authManager.signOut()
                            }
                        }
                        .foregroundColor(.red)
                        .disabled(authManager.isLoading)
                    } else {
                        Button("Login") {
                            showingLogin = true
                        }
                    }
                }
                
                Section("Test Users") {
               
    
                    
                    if !testUsersManager.testUsers.isEmpty {
                  
                            if let selectedUser = testUsersManager.selectedUser {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(selectedUser.fullName)
                                            .font(.headline)
                                            .fontWeight(.medium)
                                        Text("Age: \(selectedUser.age)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        if let supervisor = testUsersManager.supervisors.first(where: { $0.uid == selectedUser.supervisor_uid }) {
                                            Text("Supervisor: \(supervisor.fullName)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    NavigationLink("", destination: UserSelectionView())
                                        .font(.subheadline)
                                }
                                .padding(.vertical, 4)
                            } else {
                                HStack {
                                    Text("No user selected")
                                        .font(.subheadline)
                                        .foregroundColor(.red)
                                    Spacer()
                                    NavigationLink("Select User", destination: UserSelectionView())
                                        .font(.subheadline)
                                }
                                .padding(.vertical, 4)
                            }
                        
                    }
                    
                   
                    
                    Button("Add new Test User") {
                        showingAddUser = true
                    }
                    .disabled(testUsersManager.supervisors.isEmpty || testUsersManager.isLoading)
                }
                
               
            }
       
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        Task {
                            await testUsersManager.fetchSupervisors()
                            await testUsersManager.fetchTestUsers()
                        }
                    }
                    .disabled(testUsersManager.isLoading || authManager.isLoading)
                }
            }
            .task {
                await testUsersManager.fetchSupervisors()
                await testUsersManager.fetchTestUsers()
            }
            .sheet(isPresented: $showingLogin) {
                LoginView()
                    .onDisappear {
                        authManager.checkAuthStatus()
                    }
            }
            
            .sheet(isPresented: $showingAddUser) {
                UserAddView(supervisors: testUsersManager.supervisors) { user in
                    Task {
                        await testUsersManager.addTestUser(user)
                    }
                }
            }
            .overlay {
                if testUsersManager.isLoading || authManager.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
        }
    }
}












#Preview {
    SettingsView()
}
