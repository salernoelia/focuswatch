import Foundation
import SwiftData

@Model
final class LevelReward {
  var id: UUID
  var levelRequired: Int
  var title: String
  var rewardDescription: String
  var isUnlocked: Bool
  var unlockedAt: Date?

  init(
    id: UUID = UUID(),
    levelRequired: Int,
    title: String,
    rewardDescription: String,
    isUnlocked: Bool = false,
    unlockedAt: Date? = nil
  ) {
    self.id = id
    self.levelRequired = levelRequired
    self.title = title
    self.rewardDescription = rewardDescription
    self.isUnlocked = isUnlocked
    self.unlockedAt = unlockedAt
  }
}

enum RewardType: Hashable {
  case feature(String)
  case badge(String)
  case customization(String)
  case milestone(String)

  var title: String {
    switch self {
    case .feature(let name): return name
    case .badge(let name): return name
    case .customization(let name): return name
    case .milestone(let name): return name
    }
  }
}
