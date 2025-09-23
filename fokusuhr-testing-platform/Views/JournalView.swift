import SwiftUI

struct JournalEntry: Identifiable, Codable {
    var id = UUID()
    var date = Date()
    var appName: String
    var userName: String
    var userId: Int
    var entryText: String
}

struct JournalView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var selectedAppIndex: Int = 0
    @State private var selectedUserIndex: Int = 0
    @State private var entryText = ""
    @State private var isSubmitting = false
    @State private var entries: [JournalEntry] = []
    @State private var showingHistory = false
    @State private var showingSuccessAlert = false
    @FocusState private var textFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            List {
                Section("Entry Details") {
                    HStack {
                        Image(systemName: "app.badge")
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        if dataManager.apps.isEmpty {
                            Text("Loading apps...")
                                .foregroundColor(.secondary)
                        } else {
                            Picker("App", selection: $selectedAppIndex) {
                                ForEach(Array(dataManager.apps.enumerated()), id: \.offset) { index, app in
                                    Text(app.title).tag(index)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "person.circle")
                            .foregroundColor(.green)
                            .frame(width: 20)
                        
                        if dataManager.testUsers.isEmpty {
                            Text("Loading users...")
                                .foregroundColor(.secondary)
                        } else {
                            Picker("Test User", selection: $selectedUserIndex) {
                                ForEach(Array(dataManager.testUsers.enumerated()), id: \.offset) { index, user in
                                    Text(user.fullName).tag(index)
                                }
                            }
                            .pickerStyle(.menu)
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
                
                if !entries.isEmpty {
                    Section {
                        Button("View All Entries (\(entries.count))") {
                            showingHistory = true
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.blue)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
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
            .task {
                await loadData()
            }
        }
    }
    
    private var canSubmit: Bool {
        !dataManager.apps.isEmpty &&
        !dataManager.testUsers.isEmpty &&
        !entryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func loadData() async {
        await dataManager.fetchApps()
        await dataManager.fetchTestUsers()
        entries = await dataManager.fetchJournalEntries()
    }
    
    private func submitJournalEntry() {
        textFieldFocused = false
        
        guard !dataManager.apps.isEmpty && !dataManager.testUsers.isEmpty else { return }
        
        withAnimation(.easeInOut) {
            isSubmitting = true
        }
        
        let selectedApp = dataManager.apps[selectedAppIndex]
        let selectedUser = dataManager.testUsers[selectedUserIndex]
        
        let newEntry = JournalEntry(
            appName: selectedApp.title,
            userName: selectedUser.fullName,
            userId: selectedUser.id,
            entryText: entryText.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        Task {
            let success = await dataManager.saveJournalEntry(newEntry)
            
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
