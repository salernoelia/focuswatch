import SwiftUI

struct LevelView: View {
  @StateObject private var viewModel = LevelViewModel.shared

  var body: some View {
    TabView {
      mainPage
      milestonesPage
    }
    .tabViewStyle(.page)
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
      VStack(spacing: 8) {
        Text("Milestones")
          .font(.headline)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, AppConstants.UI.horizontalPadding)

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
      .padding(.top, 8)
    }
  }

  private func milestoneRow(_ milestone: LevelMilestone) -> some View {
    let isUnlocked = viewModel.currentLevel >= milestone.levelRequired

    return VStack(alignment: .leading, spacing: 6) {
      HStack {
        Text("\(milestone.levelRequired)")
          .font(.title3.bold())
          .foregroundStyle(isUnlocked ? .blue : .secondary)
          .frame(width: 35)

        VStack(alignment: .leading, spacing: 2) {
          Text(milestone.title)
            .font(.footnote.weight(.semibold))

          if !milestone.description.isEmpty {
            Text(milestone.description)
              .font(.caption2)
              .foregroundStyle(.secondary)
              .lineLimit(2)
          }
        }

        Spacer()

        if isUnlocked {
          Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(.blue)
            .font(.caption)
        }
      }
      .padding(10)
      .background(isUnlocked ? Color.blue.opacity(0.1) : Color(.gray))
      .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    .padding(.horizontal, AppConstants.UI.horizontalPadding)
    .opacity(milestone.isEnabled ? 1.0 : 0.4)
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

 
}

#Preview {
  LevelView()
}
