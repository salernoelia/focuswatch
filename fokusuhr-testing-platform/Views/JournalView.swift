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
    @State private var appName = ""
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
                        
                        TextField("App Name", text: $appName)
                            .textFieldStyle(.roundedBorder)
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
        !appName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !dataManager.testUsers.isEmpty &&
        !entryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func loadData() async {
        await dataManager.fetchTestUsers()
        entries = await dataManager.fetchJournalEntries()
    }
    
    private func submitJournalEntry() {
        textFieldFocused = false
        
        guard !dataManager.testUsers.isEmpty else { return }
        
        withAnimation(.easeInOut) {
            isSubmitting = true
        }
        
        let selectedUser = dataManager.testUsers[selectedUserIndex]
        let trimmedAppName = appName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let newEntry = JournalEntry(
            appName: trimmedAppName,
            userName: selectedUser.fullName,
            userId: Int(selectedUser.id),
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
        appName = ""
    }
}

#Preview {
    JournalView()
}
