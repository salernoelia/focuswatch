import SwiftUI
import UserNotifications
import WatchKit

struct PomodoroTimerView: View {
  @ObservedObject var viewModel: PomodoroViewModel

  var body: some View {
    VStack(spacing: 8) {
      Spacer(minLength: 24)

      Text(viewModel.currentPhaseTitle)
        .font(.caption2)
        .foregroundStyle(.secondary)

      Text(viewModel.timeString)
        .font(.system(size: 44, weight: .bold, design: .rounded))
        .monospacedDigit()

      ProgressView(value: viewModel.progress)
        .tint(viewModel.phaseColor)
        .padding(.horizontal, 8)

      HStack(spacing: 12) {
        Button(action: viewModel.toggleTimer) {
          Image(systemName: viewModel.isRunning ? "pause.fill" : "play.fill")
            .font(.title2)
        }
        .buttonStyle(.borderedProminent)
        .tint(viewModel.phaseColor)

        Button(action: viewModel.reset) {
          Image(systemName: "arrow.clockwise")
            .font(.title3)
        }
        .buttonStyle(.bordered)
      }
      .padding(.top, 4)

      Text("Wische für Einstellungen →")
        .font(.caption2)
        .foregroundStyle(.tertiary)
        .padding(.top, 4)
    }
    .padding()
  }
}
