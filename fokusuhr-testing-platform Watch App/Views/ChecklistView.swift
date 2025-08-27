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
    
    @State private var remainingItems: [Item] = []
    @State private var collectedItems: [Item] = []
    @State private var currentIndex = 0
    @State private var state: ChecklistState = .instructions
    
    var body: some View {
        switch state {
        case .instructions:
            ChecklistInstructionsView(title: instructionTitle) {
                withAnimation(.easeInOut) {
                    remainingItems = items
                    state = .checklist
                }
            }
        case .checklist:
            ChecklistMainView(
                remainingItems: $remainingItems,
                collectedItems: $collectedItems,
                currentIndex: $currentIndex,
                totalItems: items.count,
                onComplete: {
                    withAnimation {
                        state = .completed
                    }
                }
            )
        case .completed:
            ChecklistCompletionView()
        }
    }
}










