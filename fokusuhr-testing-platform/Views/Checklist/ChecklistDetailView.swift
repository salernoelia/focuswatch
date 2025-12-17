import PhotosUI
import SwiftUI

struct ChecklistDetailView: View {
  @State var checklist: Checklist
  @ObservedObject var checklistService: ChecklistSyncService
  @ObservedObject var galleryStorage: GalleryStorage
  @State private var showingAddItem = false

  var body: some View {
    List {
      Section {
        TextField("Checklist Name", text: $checklist.name)
          .font(.headline)
          .onChange(of: checklist.name, initial: false) { _, _ in
            updateChecklist()
          }

        TextField("Description", text: $checklist.description, axis: .vertical)
          .font(.subheadline)
          .foregroundColor(.secondary)
          .lineLimit(3...6)
          .onChange(of: checklist.description, initial: false) { _, _ in
            updateChecklist()
          }

        Stepper(value: $checklist.xpReward, in: 0...500, step: 10) {
          HStack {
            Text("Points Reward")
            Spacer()
            Text("\(checklist.xpReward) Points")
              .foregroundColor(.secondary)
          }
        }
        .onChange(of: checklist.xpReward, initial: false) { _, _ in
          updateChecklist()
        }
      }

      Section {
        ForEach(checklist.items) { item in
          ChecklistItemEditRow(
            item: item, checklist: $checklist, checklistService: checklistService,
            galleryStorage: galleryStorage)
        }
        .onDelete(perform: deleteItems)
        .onMove(perform: moveItems)

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
    .toolbar {
      EditButton()
    }
    .sheet(isPresented: $showingAddItem) {
      ChecklistAddItemView(
        checklist: $checklist, checklistService: checklistService, galleryStorage: galleryStorage)
    }
  }

  private func updateChecklist() {
    var data = checklistService.checklistData
    if let index = data.checklists.firstIndex(where: { $0.id == checklist.id }) {
      data.checklists[index] = checklist
      checklistService.updateChecklistData(data)
    }
  }

  private func deleteItems(offsets: IndexSet) {
    for index in offsets {
      checklist.items.remove(at: index)
    }
    updateChecklist()
  }

  private func moveItems(from source: IndexSet, to destination: Int) {
    checklist.items.move(fromOffsets: source, toOffset: destination)
    updateChecklist()
  }
}
