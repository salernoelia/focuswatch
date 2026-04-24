import SwiftUI
import UserNotifications
import WatchKit

struct PomodoroTimerView: View {
    @ObservedObject var viewModel: PomodoroViewModel

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .stroke(viewModel.phaseColor.opacity(0.2), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: 1.0 - viewModel.progress)
                    .stroke(viewModel.phaseColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.3), value: viewModel.progress)

                VStack(spacing: 0) {
                    Text(viewModel.currentPhaseTitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(viewModel.timeString)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
            }
            .frame(width: 130, height: 130)

            Spacer(minLength: 4)

            HStack(spacing: 4) {
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

#Preview {
    PomodoroTimerView(viewModel: PomodoroViewModel.shared)
}
