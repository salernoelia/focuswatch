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
}

#Preview {
  LevelView()
}
