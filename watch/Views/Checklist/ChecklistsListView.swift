import SwiftUI

struct ChecklistsListView: View {
    @StateObject private var appsManager = AppsManager.shared
    @StateObject private var checklistManager = ChecklistViewModel.shared

    private struct GroupedChecklistItem: Identifiable {
        let id: UUID
        let tag: String
        let app: AppInfo
    }

    private struct ChecklistGroup: Identifiable {
        let tag: String
        let items: [GroupedChecklistItem]

        var id: String { tag }
    }

    private var checklistApps: [AppInfo] {
        appsManager.apps.filter { $0.index >= appsManager.builtInAppCount }
    }

    private var groupedChecklistApps: [ChecklistGroup] {
        let uncategorizedTitle = String(localized: "Other")
        let groupedItems = buildGroupedChecklistItems(uncategorizedTitle: uncategorizedTitle)
        return buildChecklistGroups(from: groupedItems, uncategorizedTitle: uncategorizedTitle)
    }

    private func buildGroupedChecklistItems(uncategorizedTitle: String) -> [GroupedChecklistItem] {
        var appByIndex: [Int: AppInfo] = [:]
        for app in checklistApps {
            appByIndex[app.index] = app
        }

        var items: [GroupedChecklistItem] = []
        for (offset, checklist) in checklistManager.checklistData.checklists.enumerated() {
            let appIndex = appsManager.builtInAppCount + offset
            guard let app = appByIndex[appIndex] else { continue }

            let trimmedTag = checklist.tag.trimmingCharacters(in: .whitespacesAndNewlines)
            let tag = trimmedTag.isEmpty ? uncategorizedTitle : trimmedTag
            items.append(GroupedChecklistItem(id: checklist.id, tag: tag, app: app))
        }

        return items
    }

    private func buildChecklistGroups(
        from items: [GroupedChecklistItem],
        uncategorizedTitle: String
    ) -> [ChecklistGroup] {
        var grouped: [String: [GroupedChecklistItem]] = [:]
        for item in items {
            grouped[item.tag, default: []].append(item)
        }

        var groups: [ChecklistGroup] = []
        for (tag, tagItems) in grouped {
            let sortedItems = tagItems.sorted { lhs, rhs in
                lhs.app.title.localizedCaseInsensitiveCompare(rhs.app.title) == .orderedAscending
            }
            groups.append(ChecklistGroup(tag: tag, items: sortedItems))
        }

        return groups.sorted { lhs, rhs in
            if lhs.tag == uncategorizedTitle { return false }
            if rhs.tag == uncategorizedTitle { return true }
            return lhs.tag.localizedCaseInsensitiveCompare(rhs.tag) == .orderedAscending
        }
    }

    @ViewBuilder
    private func checklistDestination(for item: GroupedChecklistItem) -> some View {
        let checklistIndex = item.app.index - appsManager.builtInAppCount
        if checklistIndex >= 0 && checklistIndex < checklistManager.checklistData.checklists.count {
            let checklist = checklistManager.checklistData.checklists[checklistIndex]
            UniversalChecklistView(
                title: checklist.name,
                description: checklist.description,
                instructionTitle: checklist.name,
                items: checklist.items,
                checklistId: checklist.id,
                xpReward: checklist.xpReward,
                resetConfiguration: checklist.resetConfiguration
            )
        } else {
            Text(String(localized: "Checklist not found"))
                .foregroundStyle(.secondary)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if groupedChecklistApps.isEmpty {
                    Text(String(localized: "No checklists available"))
                        .foregroundStyle(.secondary)
                        .font(.caption)
                        .padding(.top, 20)
                } else {
                    ForEach(groupedChecklistApps) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(group.tag)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)

                            ForEach(group.items) { item in
                                NavigationLink {
                                    checklistDestination(for: item)
                                } label: {
                                    AppCardView(app: item.app)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 8)
        }
        .navigationTitle(String(localized: "Checklists"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ChecklistsListView()
    }
}
