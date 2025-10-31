import PhotosUI
import SwiftUI

struct ChecklistDetailView: View {
  @State var checklist: Checklist
  @ObservedObject var checklistManager: ChecklistViewModel
  @ObservedObject var galleryStorage: GalleryStorage
  @State private var showingAddItem = false

  var body: some View {
    List {
      Section {
        TextField("Checklist Name", text: $checklist.name)
          .font(.headline)
          .onChange(of: checklist.name, initial: false) { _, _ in
            checklistManager.updateChecklist(checklist)
          }

        TextField("Description", text: $checklist.description, axis: .vertical)
          .font(.subheadline)
          .foregroundColor(.secondary)
          .lineLimit(3...6)
          .onChange(of: checklist.description, initial: false) { _, _ in
            checklistManager.updateChecklist(checklist)
          }
      }

      Section {
        ForEach(checklist.items) { item in
          ChecklistItemEditRow(
            item: item, checklist: $checklist, checklistManager: checklistManager,
            galleryStorage: galleryStorage)
        }
        .onDelete(perform: deleteItems)

        Button {
          showingAddItem = true
        } label: {
          HStack {
            Image(systemName: "plus.circle.fill")
              .foregroundColor(.accentColor)
            Text("Add Item")
              .foregroundColor(.accentColor)
          }
        }
      } header: {
        Text("Items")
      }
    }
    .navigationTitle("Edit Checklist")
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
