import SwiftUI

struct JournalContentView: View {
  @ObservedObject var appsManager: AppsManager
  @ObservedObject var testUsersManager: TestUsersManager
  @Binding var selectedAppIndex: Int
  @Binding var entryText: String
  @Binding var isSubmitting: Bool
  var canSubmit: Bool
  var submitJournalEntry: () -> Void
  @Binding var entries: [PublicSchema.JournalsSelect]
  @Binding var showingHistory: Bool
  @Binding var showingSuccessAlert: Bool
  @FocusState.Binding var textFieldFocused: Bool

  var onRefresh: (() async -> Void)? = nil

  var body: some View {
    List {
      Section("Entry Details") {
        HStack {
          Image(systemName: "app.badge")
            .foregroundColor(.blue)
            .frame(width: 20)

          if appsManager.apps.isEmpty {
            Text("Loading apps...")
              .foregroundColor(.secondary)
          } else {
            Picker("App", selection: $selectedAppIndex) {
              Text("IOS App").tag(0)
              ForEach(Array(appsManager.apps.enumerated()), id: \.offset) { index, app in
                Text(app.title).tag(index + 1)
              }
            }
            .pickerStyle(.menu)
          }
        }
        HStack {
          Image(systemName: "person.circle")
            .foregroundColor(.green)
            .frame(width: 20)

          NavigationLink(destination: UserSelectionView()) {
            if testUsersManager.isNoTestUserSelected {
              Text("Your Entry (Supervisor)")
                .foregroundColor(.primary)
            } else if let selectedUser = testUsersManager.selectedUser {
              Text("Tester: \(selectedUser.fullName)")
                .foregroundColor(.primary)
            } else if testUsersManager.testUsers.isEmpty {
              Text("Loading users...")
                .foregroundColor(.secondary)
            } else {
              Text("Select User")
                .font(.subheadline)
                .foregroundColor(.blue)
            }
          }
        }
      }

      Section("Your Thoughts") {
        TextEditor(text: $entryText)
          .frame(minHeight: 100)
          .focused($textFieldFocused)
          .overlay(
            Group {
              if entryText.isEmpty {
                Text("Share your experience, thoughts, or feedback...")
                  .foregroundColor(.secondary)
                  .padding(.horizontal, 5)
                  .padding(.vertical, 8)
                  .allowsHitTesting(false)
              }
            }, alignment: .topLeading
          )
      }

      Section {
        Button(action: submitJournalEntry) {
          HStack {
            if isSubmitting {
              ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(0.8)
            } else {
              Image(systemName: "paperplane.fill")
            }
            Text(isSubmitting ? "Saving..." : "Save Entry")
          }
          .frame(maxWidth: .infinity)
          .padding()
          .background(canSubmit ? Color.accentColor : Color.gray)
          .foregroundColor(.white)
          .cornerRadius(12)
        }
        .disabled(!canSubmit || isSubmitting)
      }
      .listRowBackground(Color.clear)
    }
    .listStyle(.insetGrouped)
    .modifier(RefreshableModifier(onRefresh: onRefresh))
    .navigationTitle("Feedback")
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button("History") {
          showingHistory = true
        }
        .disabled(entries.isEmpty)
      }
    }
    .sheet(isPresented: $showingHistory) {
      JournalHistoryView(entries: entries)
    }
    .alert("Entry Saved!", isPresented: $showingSuccessAlert) {
      Button("OK") {}
    } message: {
      Text("Your journal entry has been saved successfully.")
    }
  }
}

// Helper modifier to conditionally add .refreshable
struct RefreshableModifier: ViewModifier {
  let onRefresh: (() async -> Void)?
  func body(content: Content) -> some View {
    if let onRefresh = onRefresh {
      content.refreshable { await onRefresh() }
    } else {
      content
    }
  }
}

#Preview {
  struct PreviewWrapper: View {
    @State private var selectedAppIndex = 0
    @State private var entryText = ""
    @State private var isSubmitting = false
    @State private var entries: [PublicSchema.JournalsSelect] = []
    @State private var showingHistory = false
    @State private var showingSuccessAlert = false
    @FocusState private var textFieldFocused: Bool

    var body: some View {
      JournalContentView(
        appsManager: .shared,
        testUsersManager: .shared,
        selectedAppIndex: $selectedAppIndex,
        entryText: $entryText,
        isSubmitting: $isSubmitting,
        canSubmit: true,
        submitJournalEntry: {},
        entries: $entries,
        showingHistory: $showingHistory,
        showingSuccessAlert: $showingSuccessAlert,
        textFieldFocused: $textFieldFocused,
        onRefresh: nil
      )
    }
  }
  return PreviewWrapper()
}
