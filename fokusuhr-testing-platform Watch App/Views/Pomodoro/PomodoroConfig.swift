//
//  PomodoroConfig.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 27.10.2025.
//

import SwiftUI
import UserNotifications
import WatchKit

enum VibrationFrequency: String, Codable, CaseIterable {
  case never = "Nie"
  case rare = "Selten"
  case normal = "Normal"
  case frequent = "Häufig"

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
  case light = "Leicht"
  case medium = "Mittel"
  case strong = "Stark"

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
