import SwiftUI

struct DashboardView: View {
  @StateObject private var levelViewModel = LevelViewModel.shared

  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        // Text(String(localized: "Dashboard"))
        //   .font(.title3)
        //   .fontWeight(.semibold)

        levelSection

        Spacer()
      }
      .padding()
    }
  }

  private var levelSection: some View {
    VStack(spacing: 12) {
      HStack {
        Text(String(localized: "Level"))
          .font(.caption)
          .foregroundStyle(.secondary)
        Spacer()
        Text("\(levelViewModel.currentLevel)")
          .font(.title2)
          .fontWeight(.bold)
      }

      ProgressView(value: levelViewModel.progress)
        .tint(.blue)

      HStack {
        Text("\(levelViewModel.currentXP) XP")
          .font(.caption2)
          .foregroundStyle(.secondary)
        Spacer()
        Text("\(levelViewModel.xpNeeded) XP")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }

      if let milestone = levelViewModel.nextMilestone {
        VStack(alignment: .leading, spacing: 4) {
          Text(String(localized: "Next Milestone"))
            .font(.caption2)
            .foregroundStyle(.secondary)
          Text(milestone.title)
            .font(.caption)
            .fontWeight(.medium)
          Text(String(localized: "Level") + " \(milestone.levelRequired)")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
      }
    }
    .padding()
    .background(Color.white.opacity(0.05))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
}

#Preview {
  DashboardView()
}
