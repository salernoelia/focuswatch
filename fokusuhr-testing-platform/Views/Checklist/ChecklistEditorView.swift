import PhotosUI
import SwiftUI

struct ChecklistEditorView: View {
  @ObservedObject var checklistManager: ChecklistViewModel
  @StateObject private var galleryStorage = GalleryStorage.shared
  @Environment(\.presentationMode) var presentationMode
  @State private var newChecklistId: UUID?

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
      }
      .navigationTitle("Checklists")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          NavigationLink(destination: GalleryView()) {
            Label("Photos", systemImage: "photo.stack")
          }
        }
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            let newChecklist = checklistManager.addChecklist(name: "New Checklist")
            newChecklistId = newChecklist.id
          } label: {
            Label("New Checklist", systemImage: "plus")
          }
        }
      }
      .background(
        NavigationLink(
          destination: newChecklistId.flatMap { id in
            checklistManager.data.checklists.first(where: { $0.id == id })
          }.map { checklist in
            ChecklistDetailView(
              checklist: checklist,
              checklistManager: checklistManager,
              galleryStorage: galleryStorage
            )
          },
          isActive: Binding(
            get: { newChecklistId != nil },
            set: { if !$0 { newChecklistId = nil } }
          )
        ) {
          EmptyView()
        }
        .hidden()
      )
    }
  }

  private func deleteChecklists(offsets: IndexSet) {
    for index in offsets {
      checklistManager.deleteChecklist(checklistManager.data.checklists[index])
    }
  }
}
