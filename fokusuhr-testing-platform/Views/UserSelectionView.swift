//
//  UserSelectionView.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 28.09.2025.
//


import SwiftUI

struct UserSelectionView: View {
    @StateObject private var testUsersManager = TestUsersManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    private var filteredUsers: [TestUser] {
        if searchText.isEmpty {
            return testUsersManager.testUsers
        }
        return testUsersManager.testUsers.filter { user in
            user.fullName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredUsers) { user in
                    Button {
                        testUsersManager.selectUser(user.id)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.fullName)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Text("Age: \(user.age)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if testUsersManager.selectedUserId == user.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search users")
            .navigationTitle("Select User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}