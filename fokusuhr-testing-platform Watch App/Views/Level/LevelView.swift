import SwiftUI

struct LevelView: View {
  @StateObject private var viewModel = LevelViewModel.shared

  var body: some View {
    ScrollView {
      VStack(spacing: AppConstants.UI.mediumSpacing) {
        levelHeader
        progressBar
        xpInfo
        
        if let nextMilestone = viewModel.nextMilestone {
          nextMilestoneCard(nextMilestone)
        }

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
    .navigationTitle("Level")
  }

  private var levelHeader: some View {
    

      Text("\(viewModel.currentLevel)")
        .font(.system(size: 60, weight: .bold, design: .rounded))
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

      Text("bis Level \(viewModel.currentLevel + 1)")
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
  }
  
  private func nextMilestoneCard(_ milestone: LevelMilestone) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Image(systemName: "flag.fill")
          .foregroundStyle(.yellow)
        Text("Next Milestone")
          .font(.caption2.weight(.semibold))
          .foregroundStyle(.secondary)
      }
      
      HStack {
        Text("Level \(milestone.levelRequired)")
          .font(.headline.weight(.bold))
          .foregroundStyle(.blue)
        
        Spacer()
        
        Text(milestone.title)
          .font(.caption)
          .lineLimit(1)
      }
      
      if !milestone.description.isEmpty {
        Text(milestone.description)
          .font(.caption2)
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }
    }
    .padding(12)
    .background(.quaternary)
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
}

#Preview {
  LevelView()
}
