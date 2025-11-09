import SwiftUI

struct ChecklistCompletionView: View {
  let xpReward: Int
  let checklistName: String
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    LevelRewardView(
      xpAmount: xpReward,
      title: "Amazing!"
    )
  }
}
