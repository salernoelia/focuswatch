import PhotosUI
import SwiftUI

struct ChecklistDetailView: View {
  @State var checklist: Checklist
  @ObservedObject var checklistManager: ChecklistManager
  @ObservedObject var galleryStorage: GalleryStorage
  @State private var showingAddItem = false

  var body: some View {
    List {
      Section {
        TextField("Checklist Name", text: $checklist.name)
          .onChange(of: checklist.name) { _ in
            checklistManager.updateChecklist(checklist)
          }

        TextField("Description", text: $checklist.description, axis: .vertical)
          .lineLimit(3...6)
          .onChange(of: checklist.description) { _ in
            checklistManager.updateChecklist(checklist)
          }
      }

      Section("Items") {
        ForEach(checklist.items) { item in
          ChecklistItemEditRow(
            item: item, checklist: $checklist, checklistManager: checklistManager,
            galleryStorage: galleryStorage)
        }
        .onDelete(perform: deleteItems)

        Button("Add Item") {
          showingAddItem = true
        }
      }
    }
    .navigationTitle(checklist.name)
    .navigationBarTitleDisplayMode(.inline)
    .sheet(isPresented: $showingAddItem) {
      ChecklistAddItemView(
        checklist: $checklist, checklistManager: checklistManager, galleryStorage: galleryStorage)
    }
  }

  private func deleteItems(offsets: IndexSet) {
    for index in offsets {
      let item = checklist.items[index]
      checklistManager.deleteItem(from: checklist, item: item)
      checklist.items.remove(at: index)
    }
  }
}
