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
                AddUserView(supervisors: testUsersManager.supervisors) { user in
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

struct UserSelectionView: View {
    @StateObject private var testUsersManager = TestUsersManager.shared
    @Environment(\.dismiss) private var dismiss
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
                ForEach(filteredUsers) { user in
                    Button {
                        testUsersManager.selectUser(user.id)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.fullName)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Text("Age: \(user.age)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if testUsersManager.selectedUserId == user.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search users")
            .navigationTitle("Select User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AllUsersView: View {
    @StateObject private var testUsersManager = TestUsersManager.shared
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
        List {
            ForEach(filteredUsers) { user in
                UserRow(
                    user: user,
                    supervisor: testUsersManager.supervisors.first { $0.uid == user.supervisor_uid },
                    isSelected: testUsersManager.selectedUserId == user.id
                ) {
                    Task {
                        await testUsersManager.deleteTestUser(user)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search users")
        .navigationTitle("All Users")
        .navigationBarTitleDisplayMode(.large)
    }
}



struct UserRow: View {
    let user: TestUser
    let supervisor: Supervisor?
    let isSelected: Bool
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(user.fullName)
                    .font(.body)
                    .fontWeight(isSelected ? .medium : .regular)
                HStack {
                    Text("Age: \(user.age)")
                    Text("•")
                    Text("Supervisor: \(supervisor?.fullName ?? "Unknown")")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            Spacer()
            if isSelected {
                Text("✓")
                    .foregroundColor(.green)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Text("Delete")
            }
        }
    }
}


struct AddUserView: View {
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var age = ""
    @State private var selectedSupervisorUid: String
    let supervisors: [Supervisor]
    @Environment(\.dismiss) private var dismiss
    let onAdd: (TestUser) -> Void
    
    init(supervisors: [Supervisor], onAdd: @escaping (TestUser) -> Void) {
        self.supervisors = supervisors
        self.onAdd = onAdd
        self._selectedSupervisorUid = State(initialValue: supervisors.first?.uid ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("TestUser Details") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Age", text: $age)
                        .keyboardType(.numberPad)
                }
                
                Section("Supervisor") {
                    Picker("Select Supervisor", selection: $selectedSupervisorUid) {
                        ForEach(supervisors) { supervisor in
                            Text(supervisor.fullName).tag(supervisor.uid)
                        }
                    }
                }
            }
            .navigationTitle("Add TestUser")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let nextId = (supervisors.compactMap { _ in return Int.random(in: 1000...9999) }).max() ?? 1000
                        let user = TestUser(
                            id: nextId,
                            first_name: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                            last_name: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
                            age: Int(age) ?? 0,
                            supervisor_uid: selectedSupervisorUid
                        )
                        onAdd(user)
                        dismiss()
                    }
                    .disabled(firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                             lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                             Int(age) == nil)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
