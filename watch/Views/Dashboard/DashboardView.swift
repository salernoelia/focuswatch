import SwiftUI

struct DashboardView: View {
  @StateObject private var levelViewModel = LevelViewModel.shared
  @State private var appeared = false

  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        levelSection
          .scaleEffect(appeared ? 1 : 0.7)
          .opacity(appeared ? 1 : 0)
          .animation(.spring(response: 0.5, dampingFraction: 0.55), value: appeared)

        milestonesSection
          .scaleEffect(appeared ? 1 : 0.7)
          .opacity(appeared ? 1 : 0)
          .animation(.spring(response: 0.5, dampingFraction: 0.55).delay(0.1), value: appeared)

        Spacer()
      }
      .padding(.horizontal, 8)
      .padding(.top, 8)
    }
    .navigationTitle(String(localized: "Overview"))
    .onAppear {
      appeared = true
    }
    .onDisappear {
      appeared = false
    }
  }

  private var levelSection: some View {
    NavigationLink { LevelView() } label: {
      VStack(spacing: 12) {
        HStack {
          Text(String(localized: "Level"))
            .font(.caption)
            .foregroundStyle(.secondary)
          Spacer()
          Text("\(levelViewModel.currentLevel)")
            .font(.title2)
            .fontWeight(.bold)
            .contentTransition(.numericText())
        }

        ProgressView(value: min(max(levelViewModel.progress, 0), 1))
          .tint(.blue)
          .animation(.spring(response: 0.6, dampingFraction: 0.65), value: levelViewModel.progress)

        HStack {
          Text("\(levelViewModel.currentXP)")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .contentTransition(.numericText())
          Spacer()
          Text("\(levelViewModel.xpNeeded)")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }
      .padding()
      .background(Color.white.opacity(0.05))
      .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .buttonStyle(BounceButtonStyle())
  }

  private var milestonesSection: some View {
    NavigationLink { MilestonesView() } label: {
      VStack(spacing: 12) {
        HStack {
          Text(String(localized: "Milestones"))
            .font(.caption)
            .foregroundStyle(.secondary)
          Spacer()
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
        } else {
          Text(String(localized: "All unlocked"))
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      .padding()
      .background(Color.white.opacity(0.05))
      .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .buttonStyle(BounceButtonStyle())
  }
}

struct BounceButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
      .animation(.spring(response: 0.25, dampingFraction: 0.5), value: configuration.isPressed)
  }
}

#Preview {
  DashboardView()
}
