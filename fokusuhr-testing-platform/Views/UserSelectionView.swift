import SwiftUI

struct UserSelectionView: View {
  @StateObject private var testUsersManager = TestUsersManager.shared
  @Environment(\.dismiss) private var dismiss
  @State private var searchText = ""
  @State private var showingAddUser = false

  private var filteredUsers: [UserOption] {
    let allOptions = testUsersManager.allUserOptions

    if searchText.isEmpty {
      return allOptions
    }

    return allOptions.filter { option in
      option.displayName.localizedCaseInsensitiveContains(searchText)
    }
  }

  var body: some View {
    NavigationView {
      List {
        ForEach(filteredUsers) { option in
          Button {
            testUsersManager.selectUser(option.id)
            dismiss()
          } label: {
            HStack {
              VStack(alignment: .leading, spacing: 2) {
                Text(option.displayName)
                  .font(.body)
                  .foregroundColor(.primary)

                if option.isSpecial {
                  Text("Your own journal entry")
                    .font(.caption)
                    .foregroundColor(.secondary)
                } else if let user = testUsersManager.testUsers.first(where: { $0.id == option.id })
                {
                  Text("Age: \(user.age)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
              }
              Spacer()
              if testUsersManager.selectedUserId == option.id {
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

        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Add") {
            showingAddUser = true
          }
        }
      }
      .sheet(isPresented: $showingAddUser) {
        UserAddView { user in
          Task {
            await testUsersManager.addTestUser(user)
          }
        }
      }
    }
  }
}
