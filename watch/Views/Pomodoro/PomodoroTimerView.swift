import SwiftUI
import UserNotifications
import WatchKit

struct PomodoroTimerView: View {
    @ObservedObject var viewModel: PomodoroViewModel

    var body: some View {
        VStack(spacing: 4) {
            Spacer(minLength: 20)

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

                Button(action: viewModel.reset) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                }
                .buttonStyle(.bordered)

                Button(action: viewModel.toggleTimer) {
                    Image(
                        systemName: viewModel.isRunning
                            ? "pause.fill" : "play.fill"
                    )
                    .font(.title2)
                }
                .buttonStyle(.borderedProminent)
                .tint(viewModel.phaseColor)
            }
        }
        .padding()
    }
}
