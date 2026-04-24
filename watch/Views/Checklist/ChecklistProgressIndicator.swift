import SwiftUI

struct ChecklistProgressIndicator: View {
  let orderedItemIds: [UUID]
  let itemStatuses: [UUID: ChecklistItemStatus]

  var body: some View {
    HStack(spacing: 5) {
      ForEach(orderedItemIds, id: \.self) { itemId in
        let status = itemStatuses[itemId] ?? .pending
        Circle()
          .fill(color(for: status))
          .frame(width: dotSize(for: status), height: dotSize(for: status))
          .shadow(color: glowColor(for: status), radius: status == .collected ? 4 : 0)
          .animation(.spring(response: 0.25, dampingFraction: 0.38), value: status)
      }
    }
  }

  private func color(for status: ChecklistItemStatus) -> Color {
    switch status {
    case .collected: return .green
    case .later: return .yellow
    case .pending: return Color.white.opacity(0.3)
    }
  }

  private func dotSize(for status: ChecklistItemStatus) -> CGFloat {
    switch status {
    case .collected: return 10
    case .later: return 8
    case .pending: return 6
    }
  }

  private func glowColor(for status: ChecklistItemStatus) -> Color {
    switch status {
    case .collected: return .green.opacity(0.8)
    case .later: return .yellow.opacity(0.4)
    case .pending: return .clear
    }
  }
}
