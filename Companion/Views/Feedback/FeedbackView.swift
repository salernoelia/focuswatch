import SwiftUI

struct FeedbackView: View {
  @StateObject private var appsManager = AppsManager.shared
  @StateObject private var feedbackManager = FeedbackManager.shared
  @State private var selectedAppIndex: Int = -1
  @State private var entryText = ""
  @State private var isSubmitting = false
  @State private var showingSuccessAlert = false
  @State private var showingErrorAlert = false
  @FocusState private var textFieldFocused: Bool

  var body: some View {
    NavigationView {
      List {
        Section("App") {
          HStack {
            Image(systemName: "app.badge")
              .foregroundColor(.blue)
              .frame(width: 20)
            if appsManager.apps.isEmpty {
              Text("Apps werden geladen...")
                .foregroundColor(.secondary)
            } else {
              Picker("App", selection: $selectedAppIndex) {
                Text("Generell").tag(-1)
                ForEach(Array(appsManager.apps.enumerated()), id: \.offset) { index, app in
                  Text(app.title).tag(index)
                }
              }
              .pickerStyle(.menu)
            }
          }
        }
        Section("Dein Feedback") {
          TextEditor(text: $entryText)
            .frame(minHeight: 100)
            .focused($textFieldFocused)
            .overlay(
              Group {
                if entryText.isEmpty {
                  Text("Teile dein Feedback...")
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 8)
                    .allowsHitTesting(false)
                }
              }, alignment: .topLeading
            )
        }
      }
      .listStyle(.insetGrouped)
      .navigationTitle("Feedback")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(action: submitFeedback) {
            if isSubmitting {
              ProgressView()
            } else {
              Text("Senden")
            }
          }
          .disabled(!canSubmit || isSubmitting)
        }
      }
      .alert("Feedback gesendet!", isPresented: $showingSuccessAlert) {
        Button("OK") {}
      } message: {
        Text("Dein Feedback wurde gesendet.")
      }
      .alert("Fehler", isPresented: $showingErrorAlert) {
        Button("OK") {}
      } message: {
        Text("Feedback konnte nicht gesendet werden.")
      }
    }
    .task {
      appsManager.loadApps()
    }
  }

  private var canSubmit: Bool {
    (!appsManager.apps.isEmpty || selectedAppIndex == -1)
      && !entryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  private func submitFeedback() {
    textFieldFocused = false
    if appsManager.apps.isEmpty && selectedAppIndex != -1 { return }
    withAnimation(.easeInOut) { isSubmitting = true }
    let trimmedText = entryText.trimmingCharacters(in: .whitespacesAndNewlines)
    let appName: String? =
      selectedAppIndex == -1 ? "Generell" : appsManager.apps[selectedAppIndex].title
    Task {
      let success = await feedbackManager.sendFeedback(
        appName: appName,
        description: trimmedText
      )
      await MainActor.run {
        if success {
          withAnimation(.spring()) {
            resetForm()
            showingSuccessAlert = true
          }
        } else {
          showingErrorAlert = true
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
  FeedbackView()
}
