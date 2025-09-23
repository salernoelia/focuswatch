//
//  JournalHistoryView.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 23.09.2025.
//


import SwiftUI

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
        }
        .padding(.vertical, 4)
    }
}
