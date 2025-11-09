import SwiftUI

struct ProgressListView: View {
  @StateObject private var levelViewModel = LevelViewModel.shared

  var body: some View {
    ScrollView {
      LazyVStack(spacing: 12) {
        NavigationLink(value: -1) {
          progressCard(
            title: String(localized: "Level"),
            subtitle: String(localized: "Level") + " \(levelViewModel.currentLevel)",
            color: .blue
          )
        }
        .buttonStyle(PlainButtonStyle())

        NavigationLink(value: -2) {
          progressCard(
            title: String(localized: "Milestones"),
            subtitle: nextMilestoneText,
            color: .teal
          )
        }
        .buttonStyle(PlainButtonStyle())
      }
      .padding(.horizontal, 8)
      .padding(.top, 8)
    }
    .navigationTitle(String(localized: "Progress"))
    .navigationBarTitleDisplayMode(.inline)
  }

  private func progressCard(title: String, subtitle: String, color: Color) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Circle()
          .fill(color)
          .frame(width: 12, height: 12)

        Text(title)
          .font(.headline)
          .foregroundStyle(.primary)

        Spacer()

        Image(systemName: "chevron.right")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Text(subtitle)
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
    .padding(12)
    .background(Color.white.opacity(0.05))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }

  private var nextMilestoneText: String {
    if let milestone = levelViewModel.nextMilestone {
      return milestone.title
    }
    return String(localized: "All unlocked")
  }
}

#Preview {
  NavigationStack {
    ProgressListView()
  }
}
