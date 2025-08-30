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
    
    @EnvironmentObject var watchConnector: WatchConnector
    @State private var remainingItems: [Item] = []
    @State private var collectedItems: [Item] = []
    @State private var currentIndex = 0
    @State private var state: ChecklistState = .instructions
    @State private var animationID = UUID()
    
    var body: some View {
        switch state {
        case .instructions:
            ChecklistInstructionsView(
                title: instructionTitle,
                onStart: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        remainingItems = items
                        state = .checklist
                        animationID = UUID()
                    }
                }
            )
        case .checklist:
            ChecklistMainView(
                remainingItems: $remainingItems,
                collectedItems: $collectedItems,
                currentIndex: $currentIndex,
                totalItems: items.count,
                onComplete: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        state = .completed
                        animationID = UUID()
                    }
                }
            )
            .id(animationID)
        case .completed:
            ChecklistCompletionView()
                .id(animationID)
        }
    }
}










