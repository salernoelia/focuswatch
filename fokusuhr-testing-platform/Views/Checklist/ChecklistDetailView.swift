import PhotosUI
import SwiftUI

struct ChecklistDetailView: View {
  @State var checklist: Checklist
  @ObservedObject var checklistService: ChecklistSyncService
  @ObservedObject var galleryStorage: GalleryStorage
  @State private var showingAddItems = false

  var body: some View {
    List {
      Section {
        TextField(NSLocalizedString("Checklist Name", comment: ""), text: $checklist.name)
          .font(.headline)
          .onChange(of: checklist.name, initial: false) { _, _ in
            updateChecklist()
          }

        TextField(NSLocalizedString("Description", comment: ""), text: $checklist.description, axis: .vertical)
          .font(.subheadline)
          .foregroundColor(.secondary)
          .lineLimit(3...6)
          .onChange(of: checklist.description, initial: false) { _, _ in
            updateChecklist()
          }

        Stepper(value: $checklist.xpReward, in: 0...500, step: 10) {
          HStack {
            Text(NSLocalizedString("Points Reward", comment: ""))
            Spacer()
            Text("\(checklist.xpReward) \(NSLocalizedString("Points", comment: ""))")
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
      } header: {
        HStack {
          Text(NSLocalizedString("Items", comment: ""))
          Spacer()
          Button {
            showingAddItems = true
          } label: {
            Image(systemName: "plus.circle.fill")
              .foregroundColor(.accentColor)
              .imageScale(.large)
          }
        }
      }
    }
    .navigationTitle(NSLocalizedString("Edit Checklist", comment: ""))
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      EditButton()
    }
    .sheet(isPresented: $showingAddItems) {
      UnifiedAddItemsView(
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
