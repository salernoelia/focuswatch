import Foundation
#if os(watchOS)
import WatchKit
#endif

enum FocusToolType {
  case pomodoro
  case fidgetToy
  case colorBreathing
  case fokusMeter
  case writing
}

extension FocusToolType: Identifiable {
  var id: String {
    switch self {
    case .pomodoro: return "pomodoro"
    case .fidgetToy: return "fidgetToy"
    case .colorBreathing: return "colorBreathing"
    case .fokusMeter: return "fokusMeter"
    case .writing: return "writing"
    }
  }
}

enum VibrationFrequency: String, Codable, CaseIterable {
  case never
  case rare
  case normal
  case frequent

  var localizedName: String {
    switch self {
    case .never: return String(localized: "Never")
    case .rare: return String(localized: "Rare")
    case .normal: return String(localized: "Normal")
    case .frequent: return String(localized: "Often")
    }
  }

  var intervalRange: ClosedRange<Int> {
    switch self {
    case .never: return 0...0
    case .rare: return 100...180
    case .normal: return 45...100
    case .frequent: return 15...40
    }
  }
}

enum VibrationIntensity: String, Codable, CaseIterable {
  case light
  case medium
  case strong

  var localizedName: String {
    switch self {
    case .light: return String(localized: "Light")
    case .medium: return String(localized: "Medium")
    case .strong: return String(localized: "Strong")
    }
  }

  #if os(watchOS)
    var hapticType: WKHapticType {
      switch self {
      case .light: return .start
      case .medium: return .directionUp
      case .strong: return .success
      }
    }
  #endif
}

struct PomodoroConfiguration: Codable, Hashable {
  var workMinutes: Int = 25
  var shortBreakMinutes: Int = 5
  var longBreakMinutes: Int = 15
  var roundsUntilLongBreak: Int = 4
  var vibrationFrequency: VibrationFrequency = .normal
  var vibrationIntensity: VibrationIntensity = .light
  var completionVibration: Bool = true
}

struct FidgetToyConfiguration: Codable, Hashable {
  var vibrationIntensity: VibrationIntensity = .medium
  var continuousVibration: Bool = true
}

struct ColorBreathingConfiguration: Codable, Hashable {
  var inhaleSeconds: Int = 4
  var exhaleSeconds: Int = 4
  var cycleCount: Int = 5
  var vibrationOnTransition: Bool = true
  var vibrationIntensity: VibrationIntensity = .light
}

struct FokusMeterConfiguration: Codable, Hashable {
  var enableVibration: Bool = true
  var vibrationIntensity: VibrationIntensity = .medium
}

struct WritingConfiguration: Codable, Hashable {
  var workMinutes: Double = 5.0
  var thinkMinutes: Double = 0.3
  var pauseMinutes: Double = 1.0
  var repetitions: Int = 3
  var vibrationFrequency: VibrationFrequency = .normal
  var vibrationIntensity: VibrationIntensity = .light
}

struct AppConfigurations: Codable, Hashable {
  var pomodoro: PomodoroConfiguration = PomodoroConfiguration()
  var fidgetToy: FidgetToyConfiguration = FidgetToyConfiguration()
  var colorBreathing: ColorBreathingConfiguration = ColorBreathingConfiguration()
  var fokusMeter: FokusMeterConfiguration = FokusMeterConfiguration()
  var writing: WritingConfiguration = WritingConfiguration()

  static let `default` = AppConfigurations()
}
