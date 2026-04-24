import SwiftUI

struct ChecklistCompletionView: View {
  let xpReward: Int
  let checklistName: String
  @Environment(\.dismiss) private var dismiss
  @State private var appeared = false

  var body: some View {
    LevelRewardView(
      xpAmount: xpReward,
      title: "Amazing!"
    )
    .scaleEffect(appeared ? 1 : 0.5)
    .opacity(appeared ? 1 : 0)
    .onAppear {
      withAnimation(.spring(response: 0.45, dampingFraction: 0.48)) {
        appeared = true
      }
    }
  }
}
