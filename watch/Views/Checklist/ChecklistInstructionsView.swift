import SwiftUI

struct ChecklistInstructionsView: View {
    private struct TutorialChecklistItem: ChecklistItemProtocol {
        let id = UUID()
        let title: String
        let imageName: String
    }

    let title: String
    let swipeMapping: ChecklistSwipeDirectionMapping
    let onStart: () -> Void
    @State private var hasCollectedInTutorial = false
    @State private var hasDelayedInTutorial = false
    @State private var showingDonePopup = false

    private let tutorialItem = TutorialChecklistItem(
        title: String(localized: "Tutorial"),
        imageName: ""
    )

    private var collectDirectionText: String {
        swipeMapping.collectDirection == .right ? "right" : "left"
    }

    private var delayDirectionText: String {
        swipeMapping.delayDirection == .right ? "right" : "left"
    }

    private var tutorialPrompt: String {
        if !hasCollectedInTutorial {
            return "Swipe \(collectDirectionText) to collect"
        }
        if !hasDelayedInTutorial {
            return "Swipe \(delayDirectionText) to delay"
        }
        return "Tutorial Done!"
    }

    var body: some View {
        ZStack {
            ChecklistCard(
                item: tutorialItem,
                swipeMapping: swipeMapping,
                promptText: tutorialPrompt,
                onCollect: {
                    hasCollectedInTutorial = true
                    handleTutorialCompletionIfNeeded()
                },
                onLater: {
                    hasDelayedInTutorial = true
                    handleTutorialCompletionIfNeeded()
                }
            )

        }
        .padding()
    }

    private func handleTutorialCompletionIfNeeded() {
        guard hasCollectedInTutorial && hasDelayedInTutorial else {
            return
        }

        guard !showingDonePopup else {
            return
        }

        showingDonePopup = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showingDonePopup = false
            onStart()
        }
    }
}
#Preview {
    ChecklistInstructionsView(
        title: "Test",
        swipeMapping: .collectRightDelayLeft,
        onStart: {}
    )
}
