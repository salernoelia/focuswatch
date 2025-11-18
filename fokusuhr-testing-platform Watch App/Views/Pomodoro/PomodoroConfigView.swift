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

          Divider()

          VStack(alignment: .leading, spacing: 12) {
            Text("Vibrationen")
              .font(.caption)
              .foregroundStyle(.secondary)

            NavigationLink {
              List {
                ForEach(VibrationFrequency.allCases, id: \.self) { frequency in
                  Button {
                    viewModel.settings.vibrationFrequency = frequency
                  } label: {
                    HStack {
                      Text(frequency.localizedName)
                      Spacer()
                      if viewModel.settings.vibrationFrequency == frequency {
                        Image(systemName: "checkmark")
                          .foregroundStyle(.blue)
                      }
                    }
                  }
                }
              }
              .navigationTitle("Häufigkeit")
            } label: {
              HStack {
                Text("Häufigkeit")
                  .font(.caption)
                Spacer()
                Text(viewModel.settings.vibrationFrequency.localizedName)
                  .foregroundStyle(.secondary)
                  .font(.caption)
              }
            }

            NavigationLink {
              List {
                ForEach(VibrationIntensity.allCases, id: \.self) { intensity in
                  Button {
                    viewModel.settings.vibrationIntensity = intensity
                    VibrationManager.shared.playHaptic(intensity.hapticType)
                  } label: {
                    HStack {
                      Text(intensity.localizedName)
                      Spacer()
                      if viewModel.settings.vibrationIntensity == intensity {
                        Image(systemName: "checkmark")
                          .foregroundStyle(.blue)
                      }
                    }
                  }
                }
              }
              .navigationTitle("Intensität")
            } label: {
              HStack {
                Text("Intensität")
                  .font(.caption)
                Spacer()
                Text(viewModel.settings.vibrationIntensity.localizedName)
                  .foregroundStyle(.secondary)
                  .font(.caption)
              }
            }

            Toggle("Vibration bei Abschluss", isOn: $viewModel.settings.completionVibration)
              .font(.caption)
          }
          Divider()

          VStack(spacing: 8) {
            if viewModel.currentPhase == .work {
              Button("Fokus überspringen") {
                viewModel.skipToBreak()
              }
              .font(.caption)
              .buttonStyle(.bordered)
              .tint(.orange)
            } else {
              Button("Pause überspringen") {
                viewModel.skipToWork()
              }
              .font(.caption)
              .buttonStyle(.bordered)
              .tint(.blue)
            }
          }
        }
      }
      .padding()
    }
  }
}
