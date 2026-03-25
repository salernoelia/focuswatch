import SwiftUI

struct JournalHistoryView: View {
  let entries: [PublicSchema.JournalsSelect]
  @Environment(\.dismiss) private var dismiss
  @State private var searchText = ""

  private var filteredEntries: [PublicSchema.JournalsSelect] {
    if searchText.isEmpty {
      return entries
    }
    return entries.filter { entry in
      (entry.appName?.localizedCaseInsensitiveContains(searchText) ?? false)
        || (entry.description?.localizedCaseInsensitiveContains(searchText) ?? false)
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
            ForEach(filteredEntries, id: \.id) { entry in
              JournalHistoryEntryRow(entry: entry)
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
