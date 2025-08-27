//
//  SettingsView.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 21.08.2025.
//


import SwiftUI

struct Supervisor: Identifiable, Codable {
    let id: Int
    var first_name: String
    var last_name: String
}

struct User: Identifiable, Codable {
    let id: Int
    var first_name: String
    var last_name: String
    var age: Int
    var supervisor_id: Int
}

class SettingsViewModel: ObservableObject {
    @Published var apiKey: String = ""
    @Published var supervisors: [Supervisor] = []
    @Published var users: [User] = []
    @Published var selectedUserId: Int?
    @Published var newSupervisorFirstName: String = ""
    @Published var newSupervisorLastName: String = ""
    @Published var newUserFirstName: String = ""
    @Published var newUserLastName: String = ""
    @Published var newUserAge: String = ""
    @Published var newUserSupervisorId: Int?
    
    func fetchSupervisors() {
        // TODO: API
        let sample = [
            Supervisor(id: 1, first_name: "Ari", last_name: "Kato"),
            Supervisor(id: 2, first_name: "Maya", last_name: "Perez")
        ]
        DispatchQueue.main.async {
            self.supervisors = sample
            if self.newUserSupervisorId == nil {
                self.newUserSupervisorId = sample.first?.id
            }
        }
    }
    
    func fetchUsers() {
        // TODO: API

        let sample = [
            User(id: 1, first_name: "Jon", last_name: "Doe", age: 29, supervisor_id: 1),
            User(id: 2, first_name: "Lina", last_name: "Wong", age: 34, supervisor_id: 2)
        ]
        DispatchQueue.main.async {
            self.users = sample
            if self.selectedUserId == nil {
                self.selectedUserId = sample.first?.id
            }
        }
    }
    
    // TODO: API and actual impl

    func addSupervisor() {
        let trimmedFirst = newSupervisorFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLast = newSupervisorLastName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFirst.isEmpty, !trimmedLast.isEmpty else { return }
        let nextId = (supervisors.map { $0.id }.max() ?? 0) + 1
        let s = Supervisor(id: nextId, first_name: trimmedFirst, last_name: trimmedLast)
        supervisors.append(s)
        newSupervisorFirstName = ""
        newSupervisorLastName = ""
        if newUserSupervisorId == nil {
            newUserSupervisorId = s.id
        }
    }
    
    func addUser() {
        let first = newUserFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let last = newUserLastName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !first.isEmpty, !last.isEmpty, let age = Int(newUserAge), age > 0 else { return }
        let supervisorId = newUserSupervisorId ?? (supervisors.first?.id ?? 0)
        let nextId = (users.map { $0.id }.max() ?? 0) + 1
        let u = User(id: nextId, first_name: first, last_name: last, age: age, supervisor_id: supervisorId)
        users.append(u)
        newUserFirstName = ""
        newUserLastName = ""
        newUserAge = ""
        newUserSupervisorId = nil
    }
}

struct SettingsView: View {
    @StateObject private var vm = SettingsViewModel()
    
    var body: some View {
        VStack {
            Form {
                Section("API Key") {
                    TextField("Enter API Key", text: $vm.apiKey)
                        .textContentType(.password)
                        .autocapitalization(.none)
                }
                
                Section("Supervisors") {
                    if vm.supervisors.isEmpty {
                        Text("No supervisors yet").foregroundStyle(.secondary)
                    } else {
                        ForEach(vm.supervisors) { supervisor in
                            HStack {
                                Text("\(supervisor.first_name) \(supervisor.last_name)")
                                Spacer()
                                Text("#\(supervisor.id)")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                    

                    VStack(spacing: 8) {
                        TextField("First Name", text: $vm.newSupervisorFirstName)
                        TextField("Last Name", text: $vm.newSupervisorLastName)
                        Button("Add Supervisor") {
                            vm.addSupervisor()
                        }
                        .disabled(vm.newSupervisorFirstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                  vm.newSupervisorLastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                
                Section("Users") {
                    if vm.users.isEmpty {
                        Text("No users yet").foregroundStyle(.secondary)
                    } else {
                        Picker("Select User", selection: $vm.selectedUserId) {
                            ForEach(vm.users) { user in
                                Text("\(user.first_name) \(user.last_name)").tag(user.id as Int?)
                            }
                        }
                    }
                    

                    VStack(spacing: 8) {
                        TextField("First Name", text: $vm.newUserFirstName)
                        TextField("Last Name", text: $vm.newUserLastName)
                        TextField("Age", text: $vm.newUserAge)
                            .keyboardType(.numberPad)
                        Picker("Supervisor", selection: $vm.newUserSupervisorId) {
                            ForEach(vm.supervisors) { supervisor in
                                Text("\(supervisor.first_name) \(supervisor.last_name)").tag(supervisor.id as Int?)
                            }
                        }
                        Button("Add User") {
                            vm.addUser()
                        }
                        .disabled(vm.newUserFirstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                  vm.newUserLastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                  Int(vm.newUserAge) == nil)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        vm.fetchSupervisors()
                        vm.fetchUsers()
                    }
                }
            }
            .task {
                vm.fetchSupervisors()
                vm.fetchUsers()
            }
        }
    }
}

#Preview {
    SettingsView()
}
