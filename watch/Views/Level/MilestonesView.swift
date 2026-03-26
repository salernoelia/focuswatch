import SwiftUI

struct MilestonesView: View {
  @StateObject private var viewModel = LevelViewModel.shared

  var body: some View {
    ScrollView {
      VStack(spacing: 10) {
        if viewModel.milestones.isEmpty {
          Text(String(localized: "No milestones yet"))
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding()
        } else {
          ForEach(viewModel.milestones) { milestone in
            milestoneRow(milestone)
          }
        }
      }
      .padding(.top, 8)
    }
    .navigationTitle(String(localized: "Milestones"))
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      Task {
        await viewModel.syncFromiOS()
      }
    }
  }

  private func milestoneRow(_ milestone: LevelMilestone) -> some View {
    let isUnlocked = viewModel.currentLevel >= milestone.levelRequired

    return VStack(alignment: .leading, spacing: 6) {
      HStack(alignment: .top) {
        Text("\(milestone.levelRequired)")
          .font(.title3.bold())
          .foregroundStyle(isUnlocked ? .blue : .secondary)

        Spacer()

        Image(systemName: isUnlocked ? "checkmark.circle.fill" : "circle")
          .foregroundStyle(isUnlocked ? .blue : .secondary)
          .font(.body)
      }

      Text(milestone.title)
        .font(.caption.weight(.semibold))
        .lineLimit(2)
        .frame(maxWidth: .infinity, alignment: .leading)

      if !milestone.description.isEmpty {
        Text(milestone.description)
          .font(.caption2)
          .foregroundStyle(.secondary)
          .lineLimit(3)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .padding(12)
    .background(isUnlocked ? Color.blue.opacity(0.15) : Color(.darkGray).opacity(0.3))
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .padding(.horizontal, AppConstants.UI.horizontalPadding)
    .opacity(milestone.isEnabled ? 1.0 : 0.4)
  }
}

#Preview {
  NavigationStack {
    MilestonesView()
  }
}
