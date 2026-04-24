import SwiftUI

struct LevelView: View {
  @StateObject private var viewModel = LevelViewModel.shared

  var body: some View {
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
    .navigationTitle(String(localized: "Level"))
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      Task {
        await viewModel.syncFromiOS()
      }
    }
  }

  private var levelHeader: some View {
    Text("\(viewModel.currentLevel)")
      .font(.system(size: 48, weight: .bold, design: .rounded))
      .contentTransition(.numericText())
      .animation(.spring(response: 0.4, dampingFraction: 0.45), value: viewModel.currentLevel)
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
                colors: [.blue, .cyan, .teal],
                startPoint: .leading,
                endPoint: .trailing
              )
            )
            .frame(width: geometry.size.width * viewModel.progress)
            .shadow(color: .blue.opacity(0.5), radius: 4)
        }
        .frame(height: 16)
        .animation(.spring(response: 0.6, dampingFraction: 0.65), value: viewModel.progress)
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
