import Foundation
import SwiftData

extension LevelService {
  static let defaultRewards: [RewardType: Int] = [
    .badge("Early Adopter"): 5,
    .badge("Fokus Meister"): 10,
    .badge("Fokus Legende"): 25,
    .milestone("50 Apps abgeschlossen"): 15,
    .milestone("100 Pomodoros"): 20,
    .customization("Neue Farben"): 8,
    .customization("Spezielle Sounds"): 12,
    .feature("Erweiterte Stats"): 18,
  ]

  func checkForNewRewards(at level: Int) -> [RewardType] {
    var unlockedRewards: [RewardType] = []

    for (reward, requiredLevel) in Self.defaultRewards {
      if level >= requiredLevel {
        unlockedRewards.append(reward)
      }
    }

    return unlockedRewards
  }

  func isRewardUnlocked(_ reward: RewardType) -> Bool {
    guard let progress = currentProgress,
      let requiredLevel = Self.defaultRewards[reward]
    else {
      return false
    }
    return progress.currentLevel >= requiredLevel
  }
}
