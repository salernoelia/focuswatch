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
    @State private var entries: [JournalEntry] = []
    @State private var showingHistory = false
    @State private var showingSuccessAlert = false
    @State private var showingLoginSheet = false
    @FocusState private var textFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            Group {
                if authManager.isLoggedIn {
                    journalContent
                } else {
                    loginRequiredView
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
    
    private var loginRequiredView: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Login Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Please log in to access your journal entries")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Login") {
                showingLoginSheet = true
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .padding()
        .navigationTitle("Journal")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var journalContent: some View {
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
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                textFieldFocused = false
                            }
                        }
                    }
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
        .refreshable {
            await loadData()
        }
        .navigationTitle("Journal")
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
            Button("OK") { }
        } message: {
            Text("Your journal entry has been saved successfully.")
        }
    }
    
    private var canSubmit: Bool {
        !appsManager.apps.isEmpty &&
        (testUsersManager.selectedUser != nil || testUsersManager.isNoTestUserSelected) &&
        !entryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
        
        let newEntry: JournalEntry
        
        if testUsersManager.isNoTestUserSelected {

            let supervisorName = SupervisorManager.shared.currentSupervisor?.fullName ?? "Supervisor"
            newEntry = JournalEntry(
                appName: selectedApp.title,
                userName: supervisorName,
                userId: TestUsersManager.noTestUserID, 
                entryText: entryText.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        } else if let selectedUser = testUsersManager.selectedUser {
            newEntry = JournalEntry(
                appName: selectedApp.title,
                userName: selectedUser.fullName,
                userId: selectedUser.id,
                entryText: entryText.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        } else {
            isSubmitting = false
            return
        }
        
        Task {
            let success = await journalManager.saveJournalEntry(newEntry)
            
            await MainActor.run {
                if success {
                    withAnimation(.spring()) {
                        entries.insert(newEntry, at: 0)
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
