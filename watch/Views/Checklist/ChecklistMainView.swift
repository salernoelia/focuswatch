import SwiftUI

enum ChecklistItemStatus {
    case pending
    case later
    case collected
}

struct ChecklistMainView<Item: ChecklistItemProtocol>: View {
    private enum SwipeOutcome {
        case collected
        case later

        var statusText: LocalizedStringResource {
            switch self {
            case .collected:
                return "Item Collected"
            case .later:
                return "Item for Later"
            }
        }

        var color: Color {
            switch self {
            case .collected:
                return .green
            case .later:
                return .yellow
            }
        }
    }

    private struct PendingSwipeAction {
        let item: Item
        let outcome: SwipeOutcome
        let previousStatus: ChecklistItemStatus
        let previousIndex: Int
    }

    @Binding var remainingItems: [Item]
    @Binding var collectedItems: [Item]
    @Binding var currentIndex: Int
    let allItems: [Item]
    let swipeMapping: ChecklistSwipeDirectionMapping
    private let appLogger = AppLogger.shared
    let onComplete: () -> Void
    @State private var itemStatuses: [UUID: ChecklistItemStatus] = [:]
    @State private var pendingSwipeAction: PendingSwipeAction?
    @State private var finalizeTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                Spacer()

                if !remainingItems.isEmpty, currentIndex < remainingItems.count {
                    ChecklistCard(
                        item: remainingItems[currentIndex],
                        swipeMapping: swipeMapping,
                        promptText: nil,
                        onCollect: collectCurrentItem,
                        onLater: deferCurrentItem
                    )
                    .id(remainingItems[currentIndex].id)
                }

                Spacer()

                ChecklistProgressIndicator(
                    orderedItemIds: allItems.map(\.id),
                    itemStatuses: itemStatuses
                )
                .padding(.bottom, 8)
            }

            if let pendingSwipeAction {
                undoOverlay(for: pendingSwipeAction)
                    .transition(.opacity)
                    .padding(.top, 4)
            }
        }
        .onAppear {
            configureItemStatuses()
            appLogger.logViewLifecycle(appName: "checklist", event: "open")
        }
        .onDisappear {
            finalizePendingAction()
            appLogger.logViewLifecycle(appName: "checklist", event: "close")
        }

    }

    private func configureItemStatuses() {
        var statuses: [UUID: ChecklistItemStatus] = [:]
        for item in allItems {
            statuses[item.id] = .pending
        }
        for item in collectedItems {
            statuses[item.id] = .collected
        }
        itemStatuses = statuses
    }

    private func collectCurrentItem() {
        finalizePendingAction()
        guard !remainingItems.isEmpty, currentIndex < remainingItems.count
        else { return }

        let item = remainingItems[currentIndex]
        let previousStatus = itemStatuses[item.id] ?? .pending
        let previousIndex = currentIndex

        collectedItems.append(item)
        remainingItems.remove(at: currentIndex)
        itemStatuses[item.id] = .collected
        VibrationManager.shared.mediumVibration()

        if currentIndex >= remainingItems.count {
            currentIndex = 0
        }

        pendingSwipeAction = PendingSwipeAction(
            item: item,
            outcome: .collected,
            previousStatus: previousStatus,
            previousIndex: previousIndex
        )
        schedulePendingFinalization()
    }

    private func deferCurrentItem() {
        finalizePendingAction()
        guard !remainingItems.isEmpty, currentIndex < remainingItems.count
        else { return }

        let item = remainingItems[currentIndex]
        let previousStatus = itemStatuses[item.id] ?? .pending
        let previousIndex = currentIndex

        remainingItems.remove(at: currentIndex)
        remainingItems.append(item)
        itemStatuses[item.id] = .later

        if remainingItems.count > 1, previousIndex == remainingItems.count - 1 {
            currentIndex = 0
        }

        VibrationManager.shared.lightVibration()

        pendingSwipeAction = PendingSwipeAction(
            item: item,
            outcome: .later,
            previousStatus: previousStatus,
            previousIndex: previousIndex
        )
        schedulePendingFinalization()
    }

    private func schedulePendingFinalization() {
        finalizeTask?.cancel()
        finalizeTask = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                finalizePendingAction()
            }
        }
    }

    private func finalizePendingAction() {
        finalizeTask?.cancel()
        finalizeTask = nil

        guard let finalizedAction = pendingSwipeAction else { return }
        pendingSwipeAction = nil

        if finalizedAction.outcome == .collected && remainingItems.isEmpty {
            VibrationManager.shared.strongVibration()
            onComplete()
        }
    }

    private func undoPendingAction() {
        guard let action = pendingSwipeAction else { return }

        finalizeTask?.cancel()
        finalizeTask = nil

        switch action.outcome {
        case .collected:
            if let collectedIndex = collectedItems.lastIndex(where: { $0.id == action.item.id }) {
                collectedItems.remove(at: collectedIndex)
            }

            let restoredIndex = min(action.previousIndex, remainingItems.count)
            remainingItems.insert(action.item, at: restoredIndex)
            currentIndex = restoredIndex

        case .later:
            if let movedIndex = remainingItems.lastIndex(where: { $0.id == action.item.id }) {
                remainingItems.remove(at: movedIndex)
                let restoredIndex = min(action.previousIndex, remainingItems.count)
                remainingItems.insert(action.item, at: restoredIndex)
                currentIndex = restoredIndex
            }
        }

        itemStatuses[action.item.id] = action.previousStatus
        pendingSwipeAction = nil
        VibrationManager.shared.lightVibration()
    }

    @ViewBuilder
    private func undoOverlay(for action: PendingSwipeAction) -> some View {
        VStack(spacing: 4) {
            Text(action.outcome.statusText)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(action.outcome.color)

            Button {
                undoPendingAction()
            } label: {
                Text(String(localized: "Undo", defaultValue: "Undo"))
                    .frame(maxWidth: .infinity)
            }
            .tint(action.outcome.color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color.black.opacity(1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
