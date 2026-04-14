import PhotosUI
import SwiftUI

struct ChecklistEditorView: View {
    @ObservedObject var checklistDataStore: ChecklistDataStore
    @StateObject private var galleryStorage = GalleryStorage.shared
    @EnvironmentObject var syncCoordinator: SyncCoordinator
    @Environment(\.presentationMode) var presentationMode
    @State private var newChecklistId: UUID?
    @State private var showNewChecklistDetail = false

    private struct ChecklistTagSection: Identifiable {
        let tag: String
        let checklists: [Checklist]

        var id: String { tag }
    }

    var body: some View {
        NavigationStack {
            checklistList
                .navigationTitle("Checklists")
                .refreshable {
                    syncCoordinator.forceSyncChecklists()
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        NavigationLink(destination: GalleryView()) {
                            Text("Checklist Items")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink(destination: ChecklistSettingsView()) {
                            Image(systemName: "gearshape.fill")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            let newChecklist = addChecklist(name: "New Checklist")
                            newChecklistId = newChecklist.id
                            showNewChecklistDetail = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .navigationDestination(isPresented: $showNewChecklistDetail) {
                    if let id = newChecklistId,
                        let checklist = checklistDataStore.checklistData.checklists.first(where: {
                            $0.id == id
                        })
                    {
                        ChecklistDetailView(
                            checklist: checklist,
                            checklistDataStore: checklistDataStore,
                            galleryStorage: galleryStorage
                        )
                    }
                }
        }
    }

    private func addChecklist(name: String) -> Checklist {
        let newChecklist = Checklist(name: name)
        var data = checklistDataStore.checklistData
        data.checklists.append(newChecklist)
        checklistDataStore.updateChecklistData(data)
        return newChecklist
    }

    private var checklistList: some View {
        List {
            ForEach(groupedChecklists) { section in
                Section(section.tag) {
                    ForEach(section.checklists) { checklist in
                        NavigationLink(
                            destination: ChecklistDetailView(
                                checklist: checklist,
                                checklistDataStore: checklistDataStore,
                                galleryStorage: galleryStorage
                            )
                        ) {
                            checklistRow(checklist)
                        }
                    }
                    .onDelete { offsets in
                        deleteChecklists(offsets: offsets, from: section.checklists)
                    }
                }
            }
        }
    }

    private var groupedChecklists: [ChecklistTagSection] {
        let uncategorizedTitle = NSLocalizedString("Other", comment: "")
        let grouped = Dictionary(grouping: checklistDataStore.checklistData.checklists) {
            checklist in
            let trimmedTag = checklist.tag.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedTag.isEmpty ? uncategorizedTitle : trimmedTag
        }

        return
            grouped
            .map { tag, checklists in
                ChecklistTagSection(
                    tag: tag,
                    checklists: checklists.sorted {
                        $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                    }
                )
            }
            .sorted { lhs, rhs in
                if lhs.tag == uncategorizedTitle { return false }
                if rhs.tag == uncategorizedTitle { return true }
                return lhs.tag.localizedCaseInsensitiveCompare(rhs.tag) == .orderedAscending
            }
    }

    private func checklistRow(_ checklist: Checklist) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                if !checklist.emoji.isEmpty {
                    Text(checklist.emoji)
                        .font(.title3)
                }

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

    private func deleteChecklists(offsets: IndexSet, from sectionChecklists: [Checklist]) {
        var data = checklistDataStore.checklistData
        for index in offsets {
            data.checklists.removeAll { $0.id == sectionChecklists[index].id }
        }
        checklistDataStore.updateChecklistData(data)
    }
}
