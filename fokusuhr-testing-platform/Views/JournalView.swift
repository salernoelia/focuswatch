import SwiftUI

struct JournalEntry: Identifiable, Codable {
    var id = UUID()
    var date = Date()
    var appName: String
    var userName: String
    var entryText: String
    var hasAudio: Bool = false
}

struct JournalView: View {
    @State private var appName = ""
    @State private var userName = ""
    @State private var entryText = ""
    @State private var isSubmitting = false
    @State private var isRecording = false
    @State private var audioAttached = false
    @State private var entries: [JournalEntry] = []
    @State private var showingHistory = false
    @State private var showingSuccessAlert = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case appName, userName, entryText
    }
    
    var body: some View {
        NavigationView {
            List {

                Section("Entry Details") {
                    HStack {
                        Image(systemName: "app.badge")
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        TextField("App Name", text: $appName)
                            .focused($focusedField, equals: .appName)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .userName }
                    }
                    
                    HStack {
                        Image(systemName: "person.circle")
                            .foregroundColor(.green)
                            .frame(width: 20)
                        TextField("Testuser Name", text: $userName)
                            .focused($focusedField, equals: .userName)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .entryText }
                    }
                }
                
                Section("Your Thoughts") {
                    VStack(alignment: .leading, spacing: 8) {
                        TextEditor(text: $entryText)
                            .frame(minHeight: 100)
                            .focused($focusedField, equals: .entryText)
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
                        
                        if audioAttached {
                            Label("Audio note attached", systemImage: "mic.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Section {
                    VStack(spacing: 12) {
                        Button(action: toggleRecording) {
                            HStack {
                                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                Text(isRecording ? "Stop Recording" : "Add Voice Note")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isRecording ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isSubmitting)
                        
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
        }
    }
    
    private var canSubmit: Bool {
        !appName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !entryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func toggleRecording() {
        guard !isSubmitting else { return }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            if isRecording {
                isRecording = false
                audioAttached = true
                if !entryText.isEmpty {
                    entryText += "\n\n[Audio note attached]"
                } else {
                    entryText = "[Audio note attached]"
                }
            } else {
                isRecording = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if isRecording {
                        toggleRecording()
                    }
                }
            }
        }
    }
    
    private func submitJournalEntry() {
        focusedField = nil
        
        withAnimation(.easeInOut) {
            isSubmitting = true
        }
        
        let newEntry = JournalEntry(
            appName: appName.trimmingCharacters(in: .whitespacesAndNewlines),
            userName: userName.trimmingCharacters(in: .whitespacesAndNewlines),
            entryText: entryText.trimmingCharacters(in: .whitespacesAndNewlines),
            hasAudio: audioAttached
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring()) {
                entries.insert(newEntry, at: 0)
                resetForm()
                showingSuccessAlert = true
            }
        }
    }
    
    private func resetForm() {
        appName = ""
        userName = ""
        entryText = ""
        audioAttached = false
        isSubmitting = false
    }
}

struct JournalHistoryView: View {
    let entries: [JournalEntry]
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    private var filteredEntries: [JournalEntry] {
        if searchText.isEmpty {
            return entries
        }
        return entries.filter { entry in
            entry.appName.localizedCaseInsensitiveContains(searchText) ||
            entry.userName.localizedCaseInsensitiveContains(searchText) ||
            entry.entryText.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if entries.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No Entries")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("Your journal entries will appear here")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredEntries) { entry in
                            JournalEntryRow(entry: entry)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .searchable(text: $searchText, prompt: "Search entries...")
                }
            }
            .navigationTitle("Journal History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct JournalEntryRow: View {
    let entry: JournalEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "app.badge")
                        .foregroundColor(.blue)
                    Text(entry.appName)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 8) {
                Image(systemName: "person.circle")
                    .foregroundColor(.green)
                Text("by \(entry.userName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(entry.entryText)
                .font(.body)
                .lineLimit(4)
                .padding(.vertical, 4)
            
            if entry.hasAudio {
                Label("Audio note attached", systemImage: "waveform")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding(.vertical, 4)
    }
}
