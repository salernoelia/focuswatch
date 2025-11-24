import SwiftUI
import UserNotifications
import WatchKit

struct PomodoroConfig: Codable {
  var workMinutes: Int = 25
  var shortBreakMinutes: Int = 5
  var longBreakMinutes: Int = 15
  var roundsUntilLongBreak: Int = 4
  var vibrationFrequency: VibrationFrequency = .normal
  var vibrationIntensity: VibrationIntensity = .light
  var completionVibration: Bool = true
}
