import SwiftUI

protocol ChecklistItemProtocol: Identifiable {
  var id: UUID { get }
  var title: String { get }
  var imageName: String { get }
}

extension ChecklistItem: ChecklistItemProtocol {}

enum ChecklistState {
  case instructions
  case checklist
  case completed
}

struct UniversalChecklistView<Item: ChecklistItemProtocol>: View {
  let title: String
  let instructionTitle: String
  let items: [Item]
  @Binding var selectedAppIndex: Int?

  @EnvironmentObject var watchConnector: WatchConnector
  @State private var remainingItems: [Item] = []
  @State private var collectedItems: [Item] = []
  @State private var currentIndex = 0
  @State private var state: ChecklistState = .instructions

  var body: some View {
    switch state {
    case .instructions:
      ChecklistInstructionsView(
        title: instructionTitle,
        onStart: {
          remainingItems = items
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
          state = .completed
        }
      )
      .transition(.opacity)
    case .completed:
      ChecklistCompletionView(selectedAppIndex: $selectedAppIndex)
        .transition(.opacity)
    }
  }
}
