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
      case .light: return .click
      case .medium: return .directionUp
      case .strong: return .notification
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
}

struct ColorBreathingConfiguration: Codable, Hashable {
  var inhaleSeconds: Int = 4
  var inhaleHoldSeconds: Int = 0
  var exhaleSeconds: Int = 4
  var exhaleHoldSeconds: Int = 0
  var cycleCount: Int = 5
  var vibrationOnTransition: Bool = true
  var vibrationIntensity: VibrationIntensity = .light

  enum CodingKeys: String, CodingKey {
    case inhaleSeconds
    case inhaleHoldSeconds
    case exhaleSeconds
    case exhaleHoldSeconds
    case cycleCount
    case vibrationOnTransition
    case vibrationIntensity
  }

  init() {}

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    inhaleSeconds = try container.decodeIfPresent(Int.self, forKey: .inhaleSeconds) ?? 4
    inhaleHoldSeconds = try container.decodeIfPresent(Int.self, forKey: .inhaleHoldSeconds) ?? 0
    exhaleSeconds = try container.decodeIfPresent(Int.self, forKey: .exhaleSeconds) ?? 4
    exhaleHoldSeconds = try container.decodeIfPresent(Int.self, forKey: .exhaleHoldSeconds) ?? 0
    cycleCount = try container.decodeIfPresent(Int.self, forKey: .cycleCount) ?? 5
    vibrationOnTransition = try container.decodeIfPresent(Bool.self, forKey: .vibrationOnTransition) ?? true
    vibrationIntensity = try container.decodeIfPresent(VibrationIntensity.self, forKey: .vibrationIntensity) ?? .light
  }
}

struct FokusMeterConfiguration: Codable, Hashable {
  var titleText: String = "Wie fühlst du dich?"
  var lowEmoji: String = "🚜"
  var mediumEmoji: String = "🚙"
  var highEmoji: String = "🏎️"
  
  var lowColorHex: String = "FFA500" // Orange
  var mediumColorHex: String = "008000" // Green
  var highColorHex: String = "FFA500" // Orange

  enum CodingKeys: String, CodingKey {
    case titleText
    case lowEmoji
    case mediumEmoji
    case highEmoji
    case lowColorHex
    case mediumColorHex
    case highColorHex
  }

  init() {}

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    titleText = try container.decodeIfPresent(String.self, forKey: .titleText) ?? "Wie fühlst du dich?"
    lowEmoji = try container.decodeIfPresent(String.self, forKey: .lowEmoji) ?? "🚜"
    mediumEmoji = try container.decodeIfPresent(String.self, forKey: .mediumEmoji) ?? "🚙"
    highEmoji = try container.decodeIfPresent(String.self, forKey: .highEmoji) ?? "🏎️"
    lowColorHex = try container.decodeIfPresent(String.self, forKey: .lowColorHex) ?? "FFA500"
    mediumColorHex = try container.decodeIfPresent(String.self, forKey: .mediumColorHex) ?? "008000"
    highColorHex = try container.decodeIfPresent(String.self, forKey: .highColorHex) ?? "FFA500"
  }
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
  var checklistSwipeMapping: ChecklistSwipeDirectionMapping = .collectRightDelayLeft

  enum CodingKeys: String, CodingKey {
    case pomodoro
    case fidgetToy
    case colorBreathing
    case fokusMeter
    case writing
    case checklistSwipeMapping
  }

  init() {}

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    pomodoro = try container.decodeIfPresent(PomodoroConfiguration.self, forKey: .pomodoro) ?? PomodoroConfiguration()
    fidgetToy = try container.decodeIfPresent(FidgetToyConfiguration.self, forKey: .fidgetToy) ?? FidgetToyConfiguration()
    colorBreathing = try container.decodeIfPresent(ColorBreathingConfiguration.self, forKey: .colorBreathing) ?? ColorBreathingConfiguration()
    fokusMeter = try container.decodeIfPresent(FokusMeterConfiguration.self, forKey: .fokusMeter) ?? FokusMeterConfiguration()
    writing = try container.decodeIfPresent(WritingConfiguration.self, forKey: .writing) ?? WritingConfiguration()
    checklistSwipeMapping = try container.decodeIfPresent(ChecklistSwipeDirectionMapping.self, forKey: .checklistSwipeMapping)
      ?? .collectRightDelayLeft
  }

  static let `default` = AppConfigurations()
}
