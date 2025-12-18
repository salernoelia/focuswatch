import PhotosUI
import SwiftUI

struct ChecklistEditorView: View {
  @ObservedObject var checklistService: ChecklistSyncService
  @StateObject private var galleryStorage = GalleryStorage.shared
  @StateObject private var syncCoordinator = SyncCoordinator.shared
  @Environment(\.presentationMode) var presentationMode
  @State private var newChecklistId: UUID?
  @State private var showingSyncConfirmation = false

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
            Menu {
              Button {
                let newChecklist = addChecklist(name: "New Checklist")
                newChecklistId = newChecklist.id
              } label: {
                Label(NSLocalizedString("New Checklist", comment: ""), systemImage: "plus")
              }
              Button {
                showingSyncConfirmation = true
              } label: {
                Label(NSLocalizedString("Force Sync", comment: ""), systemImage: "arrow.clockwise")
              }
            } label: {
              Image(systemName: "ellipsis.circle")
            }
          }
        }
        .background(navigationLink)
        .alert(NSLocalizedString("Force Sync", comment: ""), isPresented: $showingSyncConfirmation) {
          Button(NSLocalizedString("Cancel", comment: ""), role: .cancel) {}
          Button(NSLocalizedString("Sync", comment: "")) {
            syncCoordinator.forceSyncChecklists()
          }
        } message: {
          Text(NSLocalizedString("This will re-sync all checklists and images to the Watch. Continue?", comment: ""))
        }
    }
  }

  private func addChecklist(name: String) -> Checklist {
    let newChecklist = Checklist(name: name)
    var data = checklistService.checklistData
    data.checklists.append(newChecklist)
    checklistService.updateChecklistData(data)
    return newChecklist
  }

  private var checklistList: some View {
    List {
      ForEach(checklistService.checklistData.checklists) { checklist in
        NavigationLink(
          destination: ChecklistDetailView(
            checklist: checklist,
            checklistService: checklistService,
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
      HStack {
        Text(checklist.name)
          .font(.headline)
        Spacer()
        Text("+\(checklist.xpReward) Points")
          .font(.caption)
          .foregroundColor(.green)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(Color.green.opacity(0.1))
          .cornerRadius(8)
      }
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
        let checklist = checklistService.checklistData.checklists.first(where: { $0.id == id })
      {
        NavigationLink(
          destination: ChecklistDetailView(
            checklist: checklist,
            checklistService: checklistService,
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
    var data = checklistService.checklistData
    for index in offsets {
      data.checklists.removeAll { $0.id == checklistService.checklistData.checklists[index].id }
    }
    checklistService.updateChecklistData(data)
  }
}
