import SwiftUI

class SettingsViewModel: ObservableObject {
    @Published var supervisors: [Supervisor] = []
    @Published var users: [TestUser] = []
    @Published var selectedUserId: Int32?
    @Published var isLoading = false
    @Published var showingAddSupervisor = false
    @Published var showingAddUser = false
    @Published var showingLogin = false
    @Published var isLoggedIn = false
    @Published var currentUserEmail: String = ""
    
    private let authService = AuthService.shared
    
    init() {
        checkAuthStatus()
    }
    
    private func checkAuthStatus() {
        isLoggedIn = supabase.auth.currentSession != nil
        currentUserEmail = supabase.auth.currentUser?.email ?? ""
    }
    
    func signOut() {
        Task {
            try? await supabase.auth.signOut()
            await MainActor.run {
                isLoggedIn = false
                currentUserEmail = ""
                supervisors = []
                users = []
                selectedUserId = nil
            }
        }
    }
    
    func fetchSupervisors() {
        isLoading = true
        
        Task {
            do {
                let fetchedSupervisors = try await SupervisorService.shared.fetchSupervisors()
                await MainActor.run {
                    self.supervisors = fetchedSupervisors
                    self.isLoading = false
                }
            } catch {
                print("Failed to fetch supervisors: \(error)")
                await MainActor.run {
                    self.supervisors = []
                    self.isLoading = false
                }
            }
        }
    }
    
    func fetchUsers() {
        isLoading = true
        
        Task {
            do {
                let fetchedUsers = try await TestUserService.shared.fetchTestUsers()
                await MainActor.run {
                    self.users = fetchedUsers
                    if self.selectedUserId == nil {
                        self.selectedUserId = fetchedUsers.first?.id
                    }
                    self.isLoading = false
                }
            } catch {
                print("Failed to fetch users: \(error)")
                await MainActor.run {
                    self.users = []
                    self.isLoading = false
                }
            }
        }
    }
    
    func addSupervisor(_ supervisor: Supervisor) {
        supervisors.append(supervisor)
    }
    
    func addUser(_ user: TestUser) {
        users.append(user)
        if selectedUserId == nil {
            selectedUserId = user.id
        }
    }
    
    func deleteSupervisor(_ supervisor: Supervisor) {
        Task {
            do {
                try await SupervisorService.shared.deleteSupervisor(uid: supervisor.uid)
                await MainActor.run {
                    self.supervisors.removeAll { $0.uid == supervisor.uid }
                }
            } catch {
                print("Failed to delete supervisor: \(error)")
            }
        }
    }
    
    func deleteUser(_ user: TestUser) {
        Task {
            do {
                try await TestUserService.shared.deleteTestUser(id: user.id)
                await MainActor.run {
                    self.users.removeAll { $0.id == user.id }
                    if self.selectedUserId == user.id {
                        self.selectedUserId = self.users.first?.id
                    }
                }
            } catch {
                print("Failed to delete user: \(error)")
            }
        }
    }

struct SettingsView: View {
    @StateObject private var vm = SettingsViewModel()
    
    var body: some View {
        NavigationView {
            List {
                
                Section("Authentication") {
                    if vm.isLoggedIn {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Logged in as:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(vm.currentUserEmail)
                                .font(.body)
                        }
                        
                        Button("Sign Out") {
                            vm.signOut()
                        }
                        .foregroundColor(.red)
                    } else {
                        Button("Login") {
                            vm.showingLogin = true
                        }
                    }
                }
                
                Section {
                    HStack {
                        Text("Supervisors")
                            .font(.headline)
                        Spacer()
                        Text("\(vm.supervisors.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    if vm.supervisors.isEmpty {
                        Text("No supervisors added yet")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    } else {
                        ForEach(vm.supervisors) { supervisor in
                            SupervisorRow(supervisor: supervisor) {
                                vm.deleteSupervisor(supervisor)
                            }
                        }
                    }
                    
                    Button {
                        vm.showingAddSupervisor = true
                    } label: {
                        Text("Add Supervisor")
                    }
                    .disabled(!vm.isLoggedIn)
                }
                
                Section {
                    HStack {
                        Text("Users")
                            .font(.headline)
                        Spacer()
                        Text("\(vm.users.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    if !vm.users.isEmpty {
                        Picker("Active TestUser", selection: $vm.selectedUserId) {
                            ForEach(vm.users) { user in
                                Text(user.fullName).tag(user.id as Int32?)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    if vm.users.isEmpty {
                        Text("No users added yet")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    } else {
                        ForEach(vm.users) { user in
                            UserRow(
                                user: user,
                                supervisor: vm.supervisors.first { $0.uid == user.supervisorUid },
                                isSelected: vm.selectedUserId == user.id
                            ) {
                                vm.deleteUser(user)
                            }
                        }
                    }
                    
                    Button {
                        vm.showingAddUser = true
                    } label: {
                        Text("Add TestUser")
                    }
                    .disabled(vm.supervisors.isEmpty || !vm.isLoggedIn)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        if vm.isLoggedIn {
                            vm.fetchSupervisors()
                            vm.fetchUsers()
                        }
                    }
                    .disabled(vm.isLoading || !vm.isLoggedIn)
                }
            }
            .task {
                if vm.isLoggedIn {
                    vm.fetchSupervisors()
                    vm.fetchUsers()
                }
            }
            .onChange(of: vm.isLoggedIn) { isLoggedIn in
                if isLoggedIn {
                    vm.fetchSupervisors()
                    vm.fetchUsers()
                }
            }
            .sheet(isPresented: $vm.showingLogin) {
                LoginView()
            }
            .sheet(isPresented: $vm.showingAddSupervisor) {
                AddSupervisorView { supervisor in
                    vm.addSupervisor(supervisor)
                }
            }
            .sheet(isPresented: $vm.showingAddUser) {
                AddUserView(supervisors: vm.supervisors) { user in
                    vm.addUser(user)
                }
            }
            .overlay {
                if vm.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
        }
    }
}


struct SupervisorRow: View {
    let supervisor: Supervisor
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(supervisor.fullName)
                    .font(.body)
                Text("UID: \(supervisor.uid)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
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

struct AddSupervisorView: View {
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss
    let onAdd: (Supervisor) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Supervisor Details") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Add Supervisor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addSupervisor()
                    }
                    .disabled(firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                             lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                             email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                             isLoading)
                }
            }
        }
    }
    
    private func addSupervisor() {
        isLoading = true
        
        Task {
            do {
                let supervisor = try await SupervisorService.shared.createSupervisor(
                    firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                    lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                
                await MainActor.run {
                    onAdd(supervisor)
                    dismiss()
                }
            } catch {
                print("Failed to create supervisor: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

struct AddUserView: View {
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var age = ""
    @State private var selectedGender: PublicSchema.Genders = .hidden
    @State private var selectedSupervisorUid: UUID
    @State private var isLoading = false
    let supervisors: [Supervisor]
    @Environment(\.dismiss) private var dismiss
    let onAdd: (TestUser) -> Void
    
    init(supervisors: [Supervisor], onAdd: @escaping (TestUser) -> Void) {
        self.supervisors = supervisors
        self.onAdd = onAdd
        self._selectedSupervisorUid = State(initialValue: supervisors.first?.uid ?? UUID())
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("TestUser Details") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Age", text: $age)
                        .keyboardType(.numberPad)
                    
                    Picker("Gender", selection: $selectedGender) {
                        Text("Hidden").tag(PublicSchema.Genders.hidden)
                        Text("Male").tag(PublicSchema.Genders.male)
                        Text("Female").tag(PublicSchema.Genders.female)
                    }
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
                        addUser()
                    }
                    .disabled(firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                             lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                             Int(age) == nil ||
                             isLoading)
                }
            }
        }
    }
    
    private func addUser() {
        isLoading = true
        
        Task {
            do {
                let user = try await TestUserService.shared.createTestUser(
                    firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                    lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
                    age: Int(age) ?? 0,
                    gender: selectedGender,
                    supervisorUid: selectedSupervisorUid
                )
                
                await MainActor.run {
                    onAdd(user)
                    dismiss()
                }
            } catch {
                print("Failed to create user: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
