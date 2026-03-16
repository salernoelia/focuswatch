import SwiftUI

struct WizardConfigView: View {
  let toolType: FocusToolType
  @Binding var configurations: AppConfigurations
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationView {
      Form {
        switch toolType {
        case .pomodoro:
          PomodoroConfigSection(config: $configurations.pomodoro)
        case .fidgetToy:
          FidgetToyConfigSection(config: $configurations.fidgetToy)
        case .colorBreathing:
          ColorBreathingConfigSection(config: $configurations.colorBreathing)
        case .fokusMeter:
          FokusMeterConfigSection(config: $configurations.fokusMeter)
        case .writing:
          WritingConfigSection(config: $configurations.writing)
        }
      }
      .navigationTitle(toolTitle)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(String(localized: "Done")) {
            dismiss()
          }
        }
      }
    }
  }

  private var toolTitle: String {
    switch toolType {
    case .pomodoro: return String(localized: "Pomodoro")
    case .fidgetToy: return String(localized: "Fidget Toy")
    case .colorBreathing: return String(localized: "Color Breathing")
    case .fokusMeter: return String(localized: "Fokus Meter")
    case .writing: return String(localized: "Writing")
    }
  }
}

struct PomodoroConfigSection: View {
  @Binding var config: PomodoroConfiguration

  var body: some View {
    Section(String(localized: "Work Intervals")) {
      Stepper(
        "\(String(localized: "Work")): \(config.workMinutes) \(String(localized: "min"))",
        value: $config.workMinutes, in: 1...60
      )
      Stepper(
        "\(String(localized: "Short Break")): \(config.shortBreakMinutes) \(String(localized: "min"))",
        value: $config.shortBreakMinutes, in: 1...15
      )
      Stepper(
        "\(String(localized: "Long Break")): \(config.longBreakMinutes) \(String(localized: "min"))",
        value: $config.longBreakMinutes, in: 5...30
      )
      Stepper(
        "\(String(localized: "Rounds Until Long Break")): \(config.roundsUntilLongBreak)",
        value: $config.roundsUntilLongBreak, in: 2...8
      )
    }

    Section(String(localized: "Feedback")) {
      Picker(String(localized: "Vibration Frequency"), selection: $config.vibrationFrequency) {
        ForEach(VibrationFrequency.allCases, id: \.self) { frequency in
          Text(frequency.localizedName).tag(frequency)
        }
      }

      Picker(String(localized: "Vibration Intensity"), selection: $config.vibrationIntensity) {
        ForEach(VibrationIntensity.allCases, id: \.self) { intensity in
          Text(intensity.localizedName).tag(intensity)
        }
      }

      Toggle(String(localized: "Completion Vibration"), isOn: $config.completionVibration)
    }
  }
}

struct FidgetToyConfigSection: View {
  @Binding var config: FidgetToyConfiguration

  var body: some View {
    Section(String(localized: "Feedback")) {
      Picker(String(localized: "Vibration Intensity"), selection: $config.vibrationIntensity) {
        ForEach(VibrationIntensity.allCases, id: \.self) { intensity in
          Text(intensity.localizedName).tag(intensity)
        }
      }
    }
  }
}

struct ColorBreathingConfigSection: View {
  @Binding var config: ColorBreathingConfiguration

  var body: some View {
    Section(String(localized: "Breathing Pattern")) {
      Stepper(
        "\(String(localized: "Inhale")): \(config.inhaleSeconds) \(String(localized: "sec"))",
        value: $config.inhaleSeconds, in: 2...8
      )
      Stepper(
        "\(String(localized: "Hold In")): \(config.inhaleHoldSeconds) \(String(localized: "sec"))",
        value: $config.inhaleHoldSeconds, in: 0...8
      )
      Stepper(
        "\(String(localized: "Exhale")): \(config.exhaleSeconds) \(String(localized: "sec"))",
        value: $config.exhaleSeconds, in: 2...8
      )
      Stepper(
        "\(String(localized: "Hold Out")): \(config.exhaleHoldSeconds) \(String(localized: "sec"))",
        value: $config.exhaleHoldSeconds, in: 0...8
      )
      Stepper(
        "\(String(localized: "Cycles")): \(config.cycleCount)",
        value: $config.cycleCount, in: 1...20
      )
    }

    Section(String(localized: "Feedback")) {
      Toggle(String(localized: "Vibration on Transition"), isOn: $config.vibrationOnTransition)

      Picker(String(localized: "Vibration Intensity"), selection: $config.vibrationIntensity) {
        ForEach(VibrationIntensity.allCases, id: \.self) { intensity in
          Text(intensity.localizedName).tag(intensity)
        }
      }
      .disabled(!config.vibrationOnTransition)
    }
  }
}

struct FokusMeterConfigSection: View {
  @Binding var config: FokusMeterConfiguration

  var body: some View {
    Section {
      TextField(String(localized: "Title"), text: $config.titleText)
    }

    Section("1") {
      TextField(String(localized: "Emoji"), text: $config.lowEmoji)
      ColorPicker(String(localized: "Color"), selection: Binding(
        get: { Color(hex: config.lowColorHex) },
        set: { config.lowColorHex = $0.toHex() ?? config.lowColorHex }
      ))
    }

    Section("2") {
      TextField(String(localized: "Emoji"), text: $config.mediumEmoji)
      ColorPicker(String(localized: "Color"), selection: Binding(
        get: { Color(hex: config.mediumColorHex) },
        set: { config.mediumColorHex = $0.toHex() ?? config.mediumColorHex }
      ))
    }

    Section("3") {
      TextField(String(localized: "Emoji"), text: $config.highEmoji)
      ColorPicker(String(localized: "Color"), selection: Binding(
        get: { Color(hex: config.highColorHex) },
        set: { config.highColorHex = $0.toHex() ?? config.highColorHex }
      ))
    }
  }
}

struct WritingConfigSection: View {
  @Binding var config: WritingConfiguration

  var body: some View {
    Section(String(localized: "Session Intervals")) {
      Stepper(
        "\(String(localized: "Work")): \(String(format: "%.1f", config.workMinutes)) \(String(localized: "min"))",
        value: $config.workMinutes, in: 0.5...30, step: 0.5
      )
      Stepper(
        "\(String(localized: "Think")): \(String(format: "%.1f", config.thinkMinutes)) \(String(localized: "min"))",
        value: $config.thinkMinutes, in: 0.1...5, step: 0.1
      )
      Stepper(
        "\(String(localized: "Pause")): \(String(format: "%.1f", config.pauseMinutes)) \(String(localized: "min"))",
        value: $config.pauseMinutes, in: 0.5...10, step: 0.5
      )
      Stepper(
        "\(String(localized: "Repetitions")): \(config.repetitions)",
        value: $config.repetitions, in: 1...10
      )
    }

    Section(String(localized: "Feedback")) {
      Picker(String(localized: "Vibration Frequency"), selection: $config.vibrationFrequency) {
        ForEach(VibrationFrequency.allCases, id: \.self) { frequency in
          Text(frequency.localizedName).tag(frequency)
        }
      }

      Picker(String(localized: "Vibration Intensity"), selection: $config.vibrationIntensity) {
        ForEach(VibrationIntensity.allCases, id: \.self) { intensity in
          Text(intensity.localizedName).tag(intensity)
        }
      }
    }
  }
}

#Preview {
  WizardConfigView(
    toolType: .pomodoro,
    configurations: .constant(AppConfigurations.default)
  )
}
