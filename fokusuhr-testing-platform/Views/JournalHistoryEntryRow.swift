//
//  JournalHistoryEntryRow.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 28.09.2025.
//


import SwiftUI

struct JournalHistoryEntryRow: View {
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