import SwiftUI

struct UserAddView: View {
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