import SwiftUI

class SettingsViewModel: ObservableObject {
    @Published var supervisors: [Supervisor] = []
    @Published var users: [TestUser] = []
    @Published var selectedUserId: Int?
    @Published var isLoading = false
    @Published var showingAddSupervisor = false
    @Published var showingAddUser = false
    @Published var showingLogin = false
    @Published var isLoggedIn = false
    @Published var currentUserEmail: String = ""
    
    init() {
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        if let session = supabase.auth.currentSession {
            isLoggedIn = true
            currentUserEmail = session.user.email ?? ""
        }
    }
    
    func signOut() {
        Task {
            try? await supabase.auth.signOut()
            await MainActor.run {
                isLoggedIn = false
                currentUserEmail = ""
            }
        }
    }
    
    func fetchSupervisors() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let sample = [
                Supervisor(uid: "1", first_name: "Ari", last_name: "Kato"),
                Supervisor(uid: "2", first_name: "Maya", last_name: "Perez")
            ]
            self.supervisors = sample
            self.isLoading = false
        }
    }
    
    func fetchUsers() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let sample = [
                TestUser(id: 1, first_name: "Jon", last_name: "Doe", age: 29, supervisor_uid: "1"),
                TestUser(id: 2, first_name: "Lina", last_name: "Wong", age: 34, supervisor_uid: "2")
            ]
            self.users = sample
            if self.selectedUserId == nil {
                self.selectedUserId = sample.first?.id
            }
            self.isLoading = false
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
        supervisors.removeAll { $0.uid == supervisor.uid }
    }
    
    func deleteUser(_ user: TestUser) {
        users.removeAll { $0.id == user.id }
        if selectedUserId == user.id {
            selectedUserId = users.first?.id
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
                        Text("Users")
                            .font(.headline)
                        Spacer()
                        Text("\(vm.users.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    if !vm.users.isEmpty {
                        Picker("Active TestUser", selection: $vm.selectedUserId) {
                            ForEach(vm.users) { user in
                                Text(user.fullName).tag(user.id as Int?)
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
                                supervisor: vm.supervisors.first { $0.uid == user.supervisor_uid },
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
                    .disabled(vm.supervisors.isEmpty)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        vm.fetchSupervisors()
                        vm.fetchUsers()
                    }
                    .disabled(vm.isLoading)
                }
            }
            .task {
                vm.fetchSupervisors()
                vm.fetchUsers()
            }
            .sheet(isPresented: $vm.showingLogin) {
                LoginView()
                    .onDisappear {
                        vm.checkAuthStatus()
                    }
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
    @Environment(\.dismiss) private var dismiss
    let onAdd: (Supervisor) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Supervisor Details") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
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
                        let supervisor = Supervisor(
                            uid: UUID().uuidString,
                            first_name: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                            last_name: lastName.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        onAdd(supervisor)
                        dismiss()
                    }
                    .disabled(firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                             lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
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
                        let user = TestUser(
                            id: Int.random(in: 1000...9999),
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
