import SwiftUI
import UserNotifications
import WatchKit

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

  var hapticType: WKHapticType {
    switch self {
    case .light: return .start
    case .medium: return .directionUp
    case .strong: return .success
    }
  }
}

struct PomodoroConfig: Codable {
  var workMinutes: Int = 25
  var shortBreakMinutes: Int = 5
  var longBreakMinutes: Int = 15
  var roundsUntilLongBreak: Int = 4
  var vibrationFrequency: VibrationFrequency = .normal
  var vibrationIntensity: VibrationIntensity = .light
  var completionVibration: Bool = true
}
