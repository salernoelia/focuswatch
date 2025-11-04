import Foundation
import SwiftData

@Model
final class LevelProgress {
  var id: UUID
  var currentLevel: Int
  var currentXP: Int
  var totalXP: Int
  var lastUpdated: Date

  init(
    id: UUID = UUID(),
    currentLevel: Int = 1,
    currentXP: Int = 0,
    totalXP: Int = 0,
    lastUpdated: Date = Date()
  ) {
    self.id = id
    self.currentLevel = currentLevel
    self.currentXP = currentXP
    self.totalXP = totalXP
    self.lastUpdated = lastUpdated
  }

  static func xpForLevel(_ level: Int) -> Int {
    return level * 100
  }

  var xpNeededForNextLevel: Int {
    return Self.xpForLevel(currentLevel + 1)
  }

  var progressToNextLevel: Double {
    guard xpNeededForNextLevel > 0 else { return 0 }
    return Double(currentXP) / Double(xpNeededForNextLevel)
  }
}
