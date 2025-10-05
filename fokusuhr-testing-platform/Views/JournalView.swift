import SwiftUI

struct JournalView: View {
  @StateObject private var testUsersManager = TestUsersManager.shared
  @StateObject private var journalManager = JournalManager.shared
  @StateObject private var appsManager = AppsManager.shared
  @StateObject private var authManager = AuthManager.shared
  @State private var selectedAppIndex: Int = 0
  @State private var selectedUserIndex: Int = 0
  @State private var entryText = ""
  @State private var isSubmitting = false
  @State private var entries: [PublicSchema.JournalsSelect] = []
  @State private var showingHistory = false
  @State private var showingSuccessAlert = false
  @State private var showingLoginSheet = false
  @FocusState private var textFieldFocused: Bool

  var body: some View {
    NavigationView {
      Group {
        if authManager.isLoggedIn {
          JournalContentView(
            appsManager: appsManager,
            testUsersManager: testUsersManager,
            selectedAppIndex: $selectedAppIndex,
            entryText: $entryText,
            isSubmitting: $isSubmitting,
            canSubmit: canSubmit,
            submitJournalEntry: submitJournalEntry,
            entries: $entries,
            showingHistory: $showingHistory,
            showingSuccessAlert: $showingSuccessAlert,
            textFieldFocused: $textFieldFocused
          )
        } else {
          LoginRequiredView(showingLoginSheet: $showingLoginSheet)
        }
      }
    }
    .sheet(isPresented: $showingLoginSheet) {
      LoginView()
    }
    .onAppear {
      if !authManager.isLoggedIn {
        showingLoginSheet = true
      }
    }
    .task {
      if authManager.isLoggedIn {
        await loadData()
      }
    }
  }

  private var canSubmit: Bool {
    !appsManager.apps.isEmpty
      && (testUsersManager.selectedUser != nil
        || testUsersManager.isNoTestUserSelected)
      && !entryText.trimmingCharacters(in: .whitespacesAndNewlines)
        .isEmpty
  }

  private func loadData() async {
    await appsManager.fetchApps()
    await testUsersManager.fetchTestUsers()
    entries = await journalManager.fetchJournalEntries()
  }

  private func submitJournalEntry() {
    textFieldFocused = false

    guard !appsManager.apps.isEmpty else { return }

    withAnimation(.easeInOut) {
      isSubmitting = true
    }

    let selectedApp = appsManager.apps[selectedAppIndex]
    let trimmedText = entryText.trimmingCharacters(
      in: .whitespacesAndNewlines)

    let testUserId: Int32?
    if testUsersManager.isNoTestUserSelected {
      testUserId = nil
    } else if let selectedUser = testUsersManager.selectedUser {
      testUserId = selectedUser.id
    } else {
      isSubmitting = false
      return
    }

    Task {
      let success = await journalManager.saveJournalEntry(
        appName: selectedApp.title,
        description: trimmedText,
        testUserId: testUserId
      )

      await MainActor.run {
        if success {
          withAnimation(.spring()) {
            // Reload entries to get the newly saved one
            Task {
              entries = await journalManager.fetchJournalEntries()
            }
            resetForm()
            showingSuccessAlert = true
          }
        }
        isSubmitting = false
      }
    }
  }

  private func resetForm() {
    entryText = ""
  }
}

#Preview {
  JournalView()
}
