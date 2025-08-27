import SwiftUI

struct JournalEntry: Identifiable {
    let id = UUID()
    let date = Date()
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
    @FocusState private var focusedField: Field?
    
    enum Field {
        case appName, userName, entryText
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    inputSection
                    actionSection
                }
                .padding()
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
        }
    }
    

    
    private var inputSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                TextField("App Name", text: $appName)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .appName)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .userName
                    }
                    .accessibilityLabel("App Name")
                
                TextField("User Name", text: $userName)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .userName)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .entryText
                    }
                    .accessibilityLabel("User Name")
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Entry")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextEditor(text: $entryText)
                    .frame(minHeight: 120, maxHeight: 200)
                    .focused($focusedField, equals: .entryText)
                    .accessibilityLabel("Journal Entry Text")
                    .border(.gray)
                
                if audioAttached {
                    Label("Audio attached", systemImage: "mic.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                }
            }
        }
    }
    
    private var actionSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: toggleRecording) {
                    HStack {
                        Text(isRecording ? "Stop" : "Transcribe Voice")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isRecording ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isSubmitting)
                .accessibilityLabel(isRecording ? "Stop recording audio" : "Start recording audio")
                
                Button(action: submitJournalEntry) {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "paperplane.fill")
                        }
                        Text(isSubmitting ? "Submitting" : "Submit")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canSubmit ? Color.accentColor : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(!canSubmit || isSubmitting)
                .accessibilityLabel("Submit journal entry")
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
                        ForEach(entries) { entry in
                            JournalEntryRow(entry: entry)
                        }
                    }
                    .listStyle(.insetGrouped)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.appName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("by \(entry.userName)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(entry.entryText)
                .font(.body)
                .lineLimit(3)
            
            if entry.hasAudio {
                Label("Audio attached", systemImage: "waveform")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Journal entry for \(entry.appName) by \(entry.userName)")
    }
}

#Preview {
    JournalView()
}
