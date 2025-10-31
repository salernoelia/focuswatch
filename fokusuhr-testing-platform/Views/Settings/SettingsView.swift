import SwiftUI

struct SettingsView: View {
  @StateObject private var viewModel = SettingsViewModel()
  
  var body: some View {
    NavigationView {
      List {
        Section("Authentication") {
          if viewModel.isLoggedIn {
            VStack(alignment: .leading, spacing: 4) {
              Text("Logged in as:")
                .font(.caption)
                .foregroundColor(.secondary)
              Text(viewModel.currentUserEmail)
                .font(.body)
            }
            
            Button("Sign Out") {
              Task {
                await viewModel.signOut()
              }
            }
            .foregroundColor(.red)
            .disabled(viewModel.isLoading)
          } else {
            Button("Login") {
              viewModel.showingLogin = true
            }
          }
        }
        
        // Section("Device Information") {
        //   HStack {
        //     Text("Watch ID:")
        //       .font(.body)
        //     Spacer()
        //     Text(String(viewModel.watchUUID.prefix(8)))
        //       .font(.system(.body, design: .monospaced))
        //       .foregroundColor(.secondary)
        //   }
        // }
        
        Section("Telemetry") {
          Toggle(isOn: viewModel.hasTelemetryConsent) {
            Text("Allow Telemetry")
          }
          Text(
            "The usage data of the watch will be collected to improve the functionality of FokusUhr as it is a scientific project."
          )
          .font(.caption)
          .foregroundColor(.secondary)
          .padding(3)
        }
        
        if viewModel.isLoggedIn {
          Section("Active Testuser") {
            if !viewModel.testUsers.isEmpty {
              if let selectedUser = viewModel.selectedUser {
                HStack {
                  VStack(alignment: .leading, spacing: 4) {
                    Text(selectedUser.fullName)
                      .font(.headline)
                      .fontWeight(.medium)
                    Text("Age: \(selectedUser.age)")
                      .font(.subheadline)
                      .foregroundColor(.secondary)
                    if let supervisor = viewModel.currentSupervisor {
                      Text(
                        "Supervisor: \(supervisor.fullName)"
                      )
                      .font(.caption)
                      .foregroundColor(.secondary)
                    }
                  }
                  Spacer()
                  NavigationLink(
                    "", destination: UserSelectionView()
                  )
                  .font(.subheadline)
                }
                .padding(.vertical, 4)
              } else {
                HStack {
                  Text("No user selected")
                    .font(.subheadline)
                    .foregroundColor(.red)
                  Spacer()
                  NavigationLink(
                    "Select User",
                    destination: UserSelectionView()
                  )
                  .font(.subheadline)
                }
                .padding(.vertical, 4)
              }
            }
            
            Button("Add new Test User") {
              viewModel.showingAddUser = true
            }
            .disabled(!viewModel.isLoggedIn || viewModel.isLoading)
          }
        }
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Einstellungen")
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button("Refresh") {
          Task {
            await viewModel.refresh()
          }
        }
        .disabled(viewModel.isLoading)
      }
    }
    .task {
      await viewModel.refresh()
    }
    .refreshable {
      await viewModel.refresh()
    }
    .sheet(isPresented: $viewModel.showingLogin) {
      LoginView()
        .onDisappear {
          viewModel.checkAuthStatus()
        }
    }
    .sheet(isPresented: $viewModel.showingAddUser) {
      UserAddView { user in
        Task {
          await viewModel.addTestUser(user)
        }
      }
    }
    .overlay {
      if viewModel.isLoading {
        ProgressView("Loading...")
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(Color.black.opacity(0.1))
      }
    }
  }
}

#Preview {
  SettingsView()
}
