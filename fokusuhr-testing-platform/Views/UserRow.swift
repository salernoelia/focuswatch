//
//  UserRow.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 28.09.2025.
//


import SwiftUI

struct UserRow: View {
    let user: TestUser
    let supervisor: Supervisor?
    let isSelected: Bool
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(user.fullName)
                    .font(.body)
                    .fontWeight(isSelected ? .medium : .regular)
                HStack {
                    Text("Age: \(user.age)")
                    Text("•")
                    Text("Supervisor: \(supervisor?.fullName ?? "Unknown")")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            Spacer()
            if isSelected {
                Text("✓")
                    .foregroundColor(.green)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Text("Delete")
            }
        }
    }
}