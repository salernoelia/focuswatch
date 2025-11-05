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

  @EnvironmentObject var watchConnector: WatchConnector
  @State private var remainingItems: [Item] = []
  @State private var collectedItems: [Item] = []
  @State private var currentIndex = 0
  @State private var state: ChecklistState = .description
  @State private var hasExistingProgress = false
  @State private var isViewActive = true

  private let progressManager = ChecklistProgressManager.shared

  var body: some View {
    switch state {
    case .description:
      ChecklistDescriptionView(
        title: title,
        description: description,
        onContinue: {
          state = .instructions
        }
      )
      .transition(.opacity)
    case .instructions:
      ChecklistInstructionsView(
        title: instructionTitle,
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
          state = .checklist
        }
      )
      .transition(.opacity)
    case .checklist:
      ChecklistMainView(
        remainingItems: $remainingItems,
        collectedItems: $collectedItems,
        currentIndex: $currentIndex,
        totalItems: items.count,
        onComplete: {
          progressManager.clearProgress(for: checklistId)
          LevelService.shared.awardXP(for: .checklistCompleted)
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
    case .completed:
      ChecklistCompletionView()
        .transition(.opacity)
    }
  }

  private func checkForExistingProgress() {
    guard !items.isEmpty else { return }

    if let progress = progressManager.loadProgress(for: checklistId) {
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

    if let progress = progressManager.loadProgress(for: checklistId) {
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
