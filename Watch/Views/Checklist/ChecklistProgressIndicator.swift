import SwiftUI

struct ChecklistProgressIndicator: View {
  let orderedItemIds: [UUID]
  let itemStatuses: [UUID: ChecklistItemStatus]

  var body: some View {
    HStack(spacing: 4) {
      ForEach(orderedItemIds, id: \.self) { itemId in
        Circle()
          .fill(color(for: itemId))
          .frame(width: 6, height: 6)
          .scaleEffect(scale(for: itemId))
          .animation(.spring(response: 0.3, dampingFraction: 0.7), value: itemStatuses[itemId])
      }
    }
  }

  private func color(for itemId: UUID) -> Color {
    switch itemStatuses[itemId] ?? .pending {
    case .collected:
      return .green
    case .later:
      return .yellow
    case .pending:
      return Color.white.opacity(0.3)
    }
  }

  private func scale(for itemId: UUID) -> CGFloat {
    switch itemStatuses[itemId] ?? .pending {
    case .pending:
      return 1.0
    case .later:
      return 1.1
    case .collected:
      return 1.2
    }
  }
}
