import SwiftUI
import UserNotifications
import WatchKit

struct PomodoroConfigView: View {
  @ObservedObject var viewModel: PomodoroViewModel

  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        Text("Einstellungen")
          .font(.headline)

        VStack(alignment: .leading, spacing: 12) {
          PomodoroConfigRow(
            title: "Fokuszeit",
            value: $viewModel.settings.workMinutes,
            range: 1...60,
            unit: "Min"
          )

          PomodoroConfigRow(
            title: "Kurze Pause",
            value: $viewModel.settings.shortBreakMinutes,
            range: 1...15,
            unit: "Min"
          )

          PomodoroConfigRow(
            title: "Lange Pause",
            value: $viewModel.settings.longBreakMinutes,
            range: 1...30,
            unit: "Min"
          )

          PomodoroConfigRow(
            title: "Runden",
            value: $viewModel.settings.roundsUntilLongBreak,
            range: 2...8,
            unit: ""
          )
        }
      }
      .padding()
    }
  }
}
