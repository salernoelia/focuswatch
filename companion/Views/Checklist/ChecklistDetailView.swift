import PhotosUI
import SwiftUI

struct ChecklistDetailView: View {
    @State var checklist: Checklist
    @ObservedObject var checklistService: ChecklistSyncService
    @ObservedObject var galleryStorage: GalleryStorage
    @State private var showingAddItems = false
    private let progressManager = ChecklistProgressManager.shared
    private let commandSyncService = CommandSyncService.shared

    private var suggestedTags: [String] {
        let currentTag = checklist.tag.trimmingCharacters(in: .whitespacesAndNewlines)

        var uniqueTags = Set<String>()
        for existingChecklist in checklistService.checklistData.checklists {
            let trimmedTag = existingChecklist.tag.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedTag.isEmpty else { continue }
            guard trimmedTag != currentTag else { continue }
            uniqueTags.insert(trimmedTag)
        }

        return uniqueTags.sorted { lhs, rhs in
            lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
        }
    }

    private var resetTimeBinding: Binding<Date> {
        Binding(
            get: {
                let calendar = Calendar.current
                let now = Date()
                return calendar.date(
                    bySettingHour: checklist.resetConfiguration.hour,
                    minute: checklist.resetConfiguration.minute,
                    second: 0,
                    of: now
                ) ?? now
            },
            set: { newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                checklist.resetConfiguration.hour = components.hour ?? 2
                checklist.resetConfiguration.minute = components.minute ?? 0
                updateChecklist()
            }
        )
    }

    private var suggestedTagRows: [[String]] {
        let rowSize = 3
        var rows: [[String]] = []
        var index = 0

        while index < suggestedTags.count {
            let endIndex = min(index + rowSize, suggestedTags.count)
            rows.append(Array(suggestedTags[index..<endIndex]))
            index = endIndex
        }

        return rows
    }

    private var tagSuggestionsView: some View {
        return VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(suggestedTagRows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { tag in
                        Button {
                            checklist.tag = tag
                            updateChecklist()
                        } label: {
                            Text(tag)
                                .font(.caption)
                                .lineLimit(1)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.secondary.opacity(0.15))
                                .foregroundColor(.primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer(minLength: 0)
                }
            }
        }
    }

    var body: some View {
        List {
            Section(NSLocalizedString("General", comment: "")) {
                TextField(NSLocalizedString("Checklist Name", comment: ""), text: $checklist.name)
                    .font(.headline)
                    .onChange(of: checklist.name, initial: false) { _, _ in
                        updateChecklist()
                    }

                TextField(
                    NSLocalizedString("Description", comment: ""), text: $checklist.description,
                    axis: .vertical
                )
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3...6)
                .onChange(of: checklist.description, initial: false) { _, _ in
                    updateChecklist()
                }

                TextField(NSLocalizedString("Emoji", comment: ""), text: $checklist.emoji)
                    .font(.subheadline)
                    .onChange(of: checklist.emoji, initial: false) { _, _ in
                        let trimmed = checklist.emoji.trimmingCharacters(
                            in: .whitespacesAndNewlines)
                        if let firstCharacter = trimmed.first {
                            checklist.emoji = String(firstCharacter)
                        } else {
                            checklist.emoji = ""
                        }
                        updateChecklist()
                    }
            }

            Section(NSLocalizedString("Category", comment: "")) {
                TextField(NSLocalizedString("Category", comment: ""), text: $checklist.tag)
                    .font(.subheadline)
                    .onChange(of: checklist.tag, initial: false) { _, _ in
                        checklist.tag = checklist.tag.trimmingCharacters(
                            in: .whitespacesAndNewlines)
                        updateChecklist()
                    }

                if !suggestedTags.isEmpty {
                    tagSuggestionsView
                }
            }

            Section(NSLocalizedString("Reward", comment: "")) {
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
                Picker(
                    NSLocalizedString("Reset Interval", comment: ""),
                    selection: $checklist.resetConfiguration.interval
                ) {
                    Text(NSLocalizedString("Never", comment: "")).tag(ChecklistResetInterval.none)
                    Text(NSLocalizedString("Daily", comment: "")).tag(ChecklistResetInterval.daily)
                    Text(NSLocalizedString("Weekly", comment: "")).tag(
                        ChecklistResetInterval.weekly)
                }
                .onChange(of: checklist.resetConfiguration.interval, initial: false) { _, _ in
                    updateChecklist()
                }

                if checklist.resetConfiguration.interval != .none {
                    DatePicker(
                        NSLocalizedString("Reset Time", comment: ""),
                        selection: resetTimeBinding,
                        displayedComponents: [.hourAndMinute]
                    )

                    if checklist.resetConfiguration.interval == .weekly {
                        Picker(
                            NSLocalizedString("Reset Day", comment: ""),
                            selection: $checklist.resetConfiguration.weekday
                        ) {
                            ForEach(1...7, id: \.self) { weekday in
                                Text(Calendar.current.weekdaySymbols[weekday - 1]).tag(weekday)
                            }
                        }
                        .onChange(of: checklist.resetConfiguration.weekday, initial: false) {
                            _, _ in
                            updateChecklist()
                        }
                    }

                    Button(role: .destructive) {
                        progressManager.clearProgressAndCompletion(for: checklist.id)
                        commandSyncService.resetChecklistState(checklistId: checklist.id)
                    } label: {
                        Text(NSLocalizedString("Reset Progress Now", comment: ""))
                    }
                }
            } header: {
                Text(NSLocalizedString("Behavior", comment: ""))
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
        .listSectionSpacing(.compact)
        .toolbar {
            EditButton()
        }
        .sheet(isPresented: $showingAddItems) {
            UnifiedAddItemsView(
                checklist: $checklist, checklistService: checklistService,
                galleryStorage: galleryStorage)
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
