import SwiftUI

struct UserAddView: View {
  @State private var firstName = ""
  @State private var lastName = ""
  @State private var age = ""
  @State private var selectedGender: PublicSchema.Genders = .hidden
  @StateObject private var supervisorManager = SupervisorManager.shared
  @StateObject private var authManager = AuthManager.shared
  @Environment(\.dismiss) private var dismiss
  let onAdd: (PublicSchema.TestUsersInsert) -> Void

  init(onAdd: @escaping (PublicSchema.TestUsersInsert) -> Void) {
    self.onAdd = onAdd
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
            Text("Male").tag(PublicSchema.Genders.male)
            Text("Female").tag(PublicSchema.Genders.female)
            Text("Prefer not to say").tag(PublicSchema.Genders.hidden)
          }
        }

        if let supervisor = supervisorManager.currentSupervisor {
          Section("Supervisor") {
            HStack {
              Text("Assigned to:")
              Spacer()
              Text(supervisor.fullName)
                .foregroundColor(.secondary)
            }
          }
        } else if supervisorManager.isLoading {
          Section("Supervisor") {
            HStack {
              Text("Loading supervisor...")
              Spacer()
              ProgressView()
                .scaleEffect(0.8)
            }
          }
        } else {
          Section("Supervisor") {
            HStack {
              Text("Assigned to:")
              Spacer()
              Text("Current user")
                .foregroundColor(.secondary)
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
            guard let ageInt = Int32(age),
              let session = supabase.auth.currentSession
            else { return }

            let supervisorUid = supervisorManager.currentSupervisor?.uid ?? session.user.id

            let user = PublicSchema.TestUsersInsert(
              age: ageInt,
              firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
              gender: selectedGender,
              id: nil,
              lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
              supervisorUid: supervisorUid
            )
            onAdd(user)
            dismiss()
          }
          .disabled(
            firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
              || lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
              || Int32(age) == nil || !authManager.isLoggedIn)
        }
      }
    }
  }
}
