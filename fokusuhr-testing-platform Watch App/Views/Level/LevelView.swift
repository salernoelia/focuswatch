import SwiftUI

struct LevelView: View {
  @StateObject private var viewModel = LevelViewModel.shared

  var body: some View {
    TabView {
      mainPage
      milestonesPage
    }
    .tabViewStyle(.page)
    .onAppear {
      Task {
        await viewModel.syncFromiOS()
      }
    }
  }

  private var mainPage: some View {
    ScrollView {
      VStack(spacing: AppConstants.UI.mediumSpacing) {
        levelHeader
        progressBar
        xpInfo

        #if DEBUG
          NavigationLink(destination: LevelDebugView()) {
            HStack {
              Image(systemName: "hammer.fill")
              Text("Debug Tools")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
          }
        #endif
      }
      .padding(.horizontal, AppConstants.UI.horizontalPadding)
    }
  }

  private var milestonesPage: some View {
    ScrollView {
      VStack(spacing: 10) {
        Text("Milestones")
          .font(.title3.bold())
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, AppConstants.UI.horizontalPadding)
          .padding(.top, 4)

        if viewModel.milestones.isEmpty {
          Text("No milestones yet")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding()
        } else {
          ForEach(viewModel.milestones) { milestone in
            milestoneRow(milestone)
          }
        }
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

  private var levelHeader: some View {
    Text("\(viewModel.currentLevel)")
      .font(.system(size: 48, weight: .bold, design: .rounded))
      .contentTransition(.numericText())
  }

  private var progressBar: some View {
    VStack(spacing: 8) {
      ZStack(alignment: .leading) {
        RoundedRectangle(cornerRadius: 8)
          .fill(.quaternary)
          .frame(height: 16)

        GeometryReader { geometry in
          RoundedRectangle(cornerRadius: 8)
            .fill(
              LinearGradient(
                colors: [.blue, .cyan],
                startPoint: .leading,
                endPoint: .trailing
              )
            )
            .frame(width: geometry.size.width * viewModel.progress)
        }
        .frame(height: 16)
      }

      Text(viewModel.progressPercentage)
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
  }

  private var xpInfo: some View {
    VStack(spacing: 4) {
      Text(viewModel.xpText)
        .font(.headline)

      Text("until level \(viewModel.currentLevel + 1)")
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
  }

}

#if DEBUG
  extension LevelViewModel {
    static var previewWithMilestones: LevelViewModel {
      let vm = LevelViewModel.shared
      vm.milestones = [
        LevelMilestone(
          id: UUID(),
          levelRequired: 1,
          title: "First Steps",
          description: "Complete your first activity",
          isEnabled: true
        ),
        LevelMilestone(
          id: UUID(),
          levelRequired: 5,
          title: "Getting Started",
          description: "Reach level 5 and unlock new features",
          isEnabled: true
        ),
        LevelMilestone(
          id: UUID(),
          levelRequired: 10,
          title: "Halfway There",
          description: "You're making great progress!",
          isEnabled: true
        ),
        LevelMilestone(
          id: UUID(),
          levelRequired: 15,
          title: "Advanced User",
          description: "Unlock advanced customization options",
          isEnabled: false
        ),
        LevelMilestone(
          id: UUID(),
          levelRequired: 20,
          title: "Expert Level",
          description: "You've mastered the basics and more",
          isEnabled: true
        ),
      ]
      vm.currentLevel = 7
      vm.currentXP = 1250

      return vm
    }
  }

  #Preview("With Milestones") {
    LevelView()
      .environmentObject(LevelViewModel.previewWithMilestones)
  }
#endif
