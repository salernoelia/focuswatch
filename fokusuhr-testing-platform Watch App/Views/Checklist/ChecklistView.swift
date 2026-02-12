import SwiftUI

protocol ChecklistItemProtocol: Identifiable {
    var id: UUID { get }
    var title: String { get }
    var imageName: String { get }
}

extension ChecklistItem: ChecklistItemProtocol {}

enum ChecklistState {
    case description
    case instructions
    case cooldown
    case resumePrompt
    case checklist
    case completed
}

struct UniversalChecklistView<Item: ChecklistItemProtocol>: View {
    let title: String
    let description: String
    let instructionTitle: String
    let items: [Item]
    let checklistId: UUID
    let xpReward: Int
    let resetConfiguration: ChecklistResetConfiguration

    @EnvironmentObject var syncCoordinator: SyncCoordinator
    @State private var remainingItems: [Item] = []
    @State private var collectedItems: [Item] = []
    @State private var currentIndex = 0
    @State private var state: ChecklistState = .description
    @State private var hasExistingProgress = false
    @State private var isViewActive = true
    @State private var nextAvailableDate: Date?
    @State private var swipeMapping = SyncCoordinator.loadAppConfigurations().checklistSwipeMapping

    private let progressManager = ChecklistProgressManager.shared

    var body: some View {
        switch state {
        case .description:
            ChecklistDescriptionView(
                title: title,
                description: description,
                onContinue: {
                    if let blockedUntil = progressManager.nextAvailableDate(
                        for: checklistId,
                        resetConfiguration: resetConfiguration
                    ) {
                        nextAvailableDate = blockedUntil
                        state = .cooldown
                    } else {
                        state = .instructions
                    }
                }
            )
            .transition(.opacity)
        case .cooldown:
            VStack(spacing: 10) {
                Text(String(localized: "Try again later"))
                    .font(.headline)
                if let nextAvailableDate {
                    Text(nextAvailableDate, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Button(String(localized: "Back")) {
                    state = .description
                }
            }
            .padding()
        case .instructions:
            ChecklistInstructionsView(
                title: instructionTitle,
                swipeMapping: swipeMapping,
                onStart: {
                    checkAndLoadProgress()
                }
            )
            .transition(.opacity)
            .onAppear {
                checkForExistingProgress()
            }
        case .resumePrompt:
            ChecklistResumePromptView(
                onResume: {
                    state = .checklist
                },
                onRestart: {
                    progressManager.clearProgress(for: checklistId)
                    remainingItems = items
                    collectedItems = []
                    currentIndex = 0
                    state = .instructions
                }
            )
            .transition(.opacity)
        case .checklist:
            ChecklistMainView(
                remainingItems: $remainingItems,
                collectedItems: $collectedItems,
                currentIndex: $currentIndex,
                allItems: items,
                swipeMapping: swipeMapping,
                onComplete: {
                    progressManager.clearProgress(for: checklistId)
                    progressManager.markCompleted(for: checklistId)
                    LevelService.shared.addXP(xpReward, reason: "Checklist completed: \(title)")
                    state = .completed
                }
            )
            .transition(.opacity)
            .onAppear {
                isViewActive = true
            }
            .onDisappear {
                guard isViewActive else { return }
                isViewActive = false

                if state == .checklist && !remainingItems.isEmpty {
                    saveProgress()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .appConfigurationsUpdated)) { notification in
                if let configurations = notification.object as? AppConfigurations {
                    swipeMapping = configurations.checklistSwipeMapping
                } else {
                    swipeMapping = SyncCoordinator.loadAppConfigurations().checklistSwipeMapping
                }
            }
        case .completed:
            ChecklistCompletionView(
                xpReward: xpReward,
                checklistName: title
            )
            .transition(.opacity)
        }
    }

    private func checkForExistingProgress() {
        guard !items.isEmpty else { return }

        if let progress = progressManager.loadProgress(for: checklistId, resetConfiguration: resetConfiguration) {
            let collectedIds = Set(progress.collectedItemIds)
            let remaining = items.filter { !collectedIds.contains($0.id) }

            if !remaining.isEmpty && !collectedIds.isEmpty {
                collectedItems = items.filter { collectedIds.contains($0.id) }
                remainingItems = remaining
                let validIndex = min(progress.currentIndex, remainingItems.count - 1)
                currentIndex = max(0, validIndex)
                state = .resumePrompt
            }
        }
    }

    private func checkAndLoadProgress() {
        guard !items.isEmpty else {
            state = .checklist
            return
        }

        if let progress = progressManager.loadProgress(for: checklistId, resetConfiguration: resetConfiguration) {
            let collectedIds = Set(progress.collectedItemIds)
            collectedItems = items.filter { collectedIds.contains($0.id) }
            remainingItems = items.filter { !collectedIds.contains($0.id) }

            if !remainingItems.isEmpty {
                currentIndex = min(progress.currentIndex, remainingItems.count - 1)
                currentIndex = max(0, currentIndex)
            } else {
                remainingItems = items
                collectedItems = []
                currentIndex = 0
            }
        } else {
            remainingItems = items
            collectedItems = []
            currentIndex = 0
        }
        state = .checklist
    }

    private func saveProgress() {
        guard !collectedItems.isEmpty || currentIndex > 0 else {
            return
        }

        guard currentIndex >= 0 && currentIndex < max(1, remainingItems.count) else {
            return
        }

        let collectedIds = collectedItems.map { $0.id }
        progressManager.saveProgress(
            for: checklistId,
            collectedItemIds: collectedIds,
            currentIndex: currentIndex
        )
    }
}
