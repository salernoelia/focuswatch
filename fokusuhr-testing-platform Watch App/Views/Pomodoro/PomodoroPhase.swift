import SwiftUI
import UserNotifications
import WatchKit

enum PomodoroPhase: String, Codable {
  case work
  case shortBreak
  case longBreak

  var title: String {
    switch self {
    case .work: return "Fokuszeit"
    case .shortBreak: return "Kurze Pause"
    case .longBreak: return "Lange Pause"
    }
  }

  var color: Color {
    switch self {
    case .work: return .blue
    case .shortBreak: return .green
    case .longBreak: return .purple
    }
  }
}
