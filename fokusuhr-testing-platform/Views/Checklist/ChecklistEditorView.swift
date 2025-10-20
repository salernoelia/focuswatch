import PhotosUI
import SwiftUI

struct ChecklistEditorView: View {
  @ObservedObject var checklistManager: ChecklistManager
  @StateObject private var galleryStorage = GalleryStorage.shared
  @Environment(\.presentationMode) var presentationMode

  var body: some View {
    NavigationView {
      List {
        ForEach(checklistManager.data.checklists) { checklist in
          NavigationLink(
            destination: ChecklistDetailView(
              checklist: checklist, checklistManager: checklistManager,
              galleryStorage: galleryStorage)
          ) {
            VStack(alignment: .leading, spacing: 4) {
              Text(checklist.name)
                .font(.headline)
              if !checklist.description.isEmpty {
                Text(checklist.description)
                  .font(.caption)
                  .foregroundColor(.secondary)
                  .lineLimit(2)
              }
              Text("\(checklist.items.count) items")
                .font(.caption2)
                .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
          }
        }
        .onDelete(perform: deleteChecklists)

        Button {
          checklistManager.addChecklist(name: "New Checklist")
        } label: {
          HStack {
            Image(systemName: "plus.circle.fill")
              .foregroundColor(.accentColor)
            Text("Add Checklist")
              .foregroundColor(.accentColor)
          }
        }
      }
      .navigationTitle("Checklists")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            presentationMode.wrappedValue.dismiss()
          }
        }
      }
    }
  }

  private func deleteChecklists(offsets: IndexSet) {
    for index in offsets {
      checklistManager.deleteChecklist(checklistManager.data.checklists[index])
    }
  }
}
