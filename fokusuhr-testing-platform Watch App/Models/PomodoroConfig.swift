//
//  PomodoroConfig.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 27.10.2025.
//

import SwiftUI
import UserNotifications
import WatchKit

struct PomodoroConfig: Codable {
  var workMinutes: Int = 25
  var shortBreakMinutes: Int = 5
  var longBreakMinutes: Int = 15
  var roundsUntilLongBreak: Int = 4
}
