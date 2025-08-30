import SwiftUI

struct Supervisor: Identifiable, Codable {
    let id: Int
    var first_name: String
    var last_name: String
    
    var fullName: String {
        "\(first_name) \(last_name)"
    }
}

struct User: Identifiable, Codable {
    let id: Int
    var first_name: String
    var last_name: String
    var age: Int
    var supervisor_id: Int
    
    var fullName: String {
        "\(first_name) \(last_name)"
    }
}

class SettingsViewModel: ObservableObject {
    @Published var apiKey: String = ""
    @Published var supervisors: [Supervisor] = []
    @Published var users: [User] = []
    @Published var selectedUserId: Int?
    @Published var isLoading = false
    @Published var showingAddSupervisor = false
    @Published var showingAddUser = false
    
    func fetchSupervisors() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let sample = [
                Supervisor(id: 1, first_name: "Ari", last_name: "Kato"),
                Supervisor(id: 2, first_name: "Maya", last_name: "Perez")
            ]
            self.supervisors = sample
            self.isLoading = false
        }
    }
    
    func fetchUsers() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let sample = [
                User(id: 1, first_name: "Jon", last_name: "Doe", age: 29, supervisor_id: 1),
                User(id: 2, first_name: "Lina", last_name: "Wong", age: 34, supervisor_id: 2)
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
    
    func addUser(_ user: User) {
        users.append(user)
        if selectedUserId == nil {
            selectedUserId = user.id
        }
    }
    
    func deleteSupervisor(_ supervisor: Supervisor) {
        supervisors.removeAll { $0.id == supervisor.id }
    }
    
    func deleteUser(_ user: User) {
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
                
                Section("API Configuration") {
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        SecureField("Enter API Key", text: $vm.apiKey)
                    }
                    
                    if !vm.apiKey.isEmpty {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("API Key Configured")
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Section {
                    HStack {
                        Image(systemName: "person.badge.key.fill")
                            .foregroundColor(.orange)
                            .frame(width: 20)
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
                        Label("Add Supervisor", systemImage: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                
                Section {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.green)
                            .frame(width: 20)
                        Text("Users")
                            .font(.headline)
                        Spacer()
                        Text("\(vm.users.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    if !vm.users.isEmpty {
                        Picker("Active User", selection: $vm.selectedUserId) {
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
                                supervisor: vm.supervisors.first { $0.id == user.supervisor_id },
                                isSelected: vm.selectedUserId == user.id
                            ) {
                                vm.deleteUser(user)
                            }
                        }
                    }
                    
                    Button {
                        vm.showingAddUser = true
                    } label: {
                        Label("Add User", systemImage: "plus.circle.fill")
                            .foregroundColor(.blue)
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
            Image(systemName: "person.circle.fill")
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(supervisor.fullName)
                    .font(.body)
                Text("ID: \(supervisor.id)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct UserRow: View {
    let user: User
    let supervisor: Supervisor?
    let isSelected: Bool
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: isSelected ? "person.circle.fill" : "person.circle")
                .foregroundColor(isSelected ? .green : .secondary)
            
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
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
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
                            id: Int.random(in: 1000...9999),
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
    @State private var selectedSupervisorId: Int
    let supervisors: [Supervisor]
    @Environment(\.dismiss) private var dismiss
    let onAdd: (User) -> Void
    
    init(supervisors: [Supervisor], onAdd: @escaping (User) -> Void) {
        self.supervisors = supervisors
        self.onAdd = onAdd
        self._selectedSupervisorId = State(initialValue: supervisors.first?.id ?? 0)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("User Details") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Age", text: $age)
                        .keyboardType(.numberPad)
                }
                
                Section("Supervisor") {
                    Picker("Select Supervisor", selection: $selectedSupervisorId) {
                        ForEach(supervisors) { supervisor in
                            Text(supervisor.fullName).tag(supervisor.id)
                        }
                    }
                }
            }
            .navigationTitle("Add User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let user = User(
                            id: Int.random(in: 1000...9999),
                            first_name: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                            last_name: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
                            age: Int(age) ?? 0,
                            supervisor_id: selectedSupervisorId
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