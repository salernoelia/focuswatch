import PhotosUI
import SwiftUI

struct ChecklistEditorView: View {
  @ObservedObject var checklistManager: ChecklistViewModel
  @StateObject private var galleryStorage = GalleryStorage.shared
  @Environment(\.presentationMode) var presentationMode
  @State private var newChecklistId: UUID?

  var body: some View {
    NavigationView {
      checklistList
        .navigationTitle("Checklists")
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            NavigationLink(destination: GalleryView()) {
              Text("Photos")
            }
          }
          ToolbarItem(placement: .topBarTrailing) {
            Button {
              let newChecklist = checklistManager.addChecklist(name: "New Checklist")
              newChecklistId = newChecklist.id
            } label: {
              Text("New Checklist")
            }
          }
        }
        .background(navigationLink)
    }
  }

  private var checklistList: some View {
    List {
      ForEach(checklistManager.data.checklists) { checklist in
        NavigationLink(
          destination: ChecklistDetailView(
            checklist: checklist,
            checklistManager: checklistManager,
            galleryStorage: galleryStorage
          )
        ) {
          checklistRow(checklist)
        }
      }
      .onDelete(perform: deleteChecklists)
    }
  }

  private func checklistRow(_ checklist: Checklist) -> some View {
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

  private var navigationLink: some View {
    Group {
      if let id = newChecklistId,
        let checklist = checklistManager.data.checklists.first(where: { $0.id == id })
      {
        NavigationLink(
          destination: ChecklistDetailView(
            checklist: checklist,
            checklistManager: checklistManager,
            galleryStorage: galleryStorage
          ),
          isActive: Binding(
            get: { newChecklistId != nil },
            set: { if !$0 { newChecklistId = nil } }
          )
        ) {
          EmptyView()
        }
        .hidden()
      }
    }
  }

  private func deleteChecklists(offsets: IndexSet) {
    for index in offsets {
      checklistManager.deleteChecklist(checklistManager.data.checklists[index])
    }
  }
}
