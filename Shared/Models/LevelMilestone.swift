import Foundation

struct LevelMilestone: Codable, Identifiable, Hashable {
  var id: UUID
  var levelRequired: Int
  var title: String
  var description: String
  var isEnabled: Bool

  init(
    id: UUID = UUID(),
    levelRequired: Int,
    title: String,
    description: String = "",
    isEnabled: Bool = true
  ) {
    self.id = id
    self.levelRequired = levelRequired
    self.title = title
    self.description = description
    self.isEnabled = isEnabled
  }
}

struct LevelData: Codable {
  var currentLevel: Int
  var currentXP: Int
  var totalXP: Int
  var milestones: [LevelMilestone]
  var lastUpdated: Date

  init(
    currentLevel: Int = 1,
    currentXP: Int = 0,
    totalXP: Int = 0,
    milestones: [LevelMilestone] = [],
    lastUpdated: Date = Date()
  ) {
    self.currentLevel = currentLevel
    self.currentXP = currentXP
    self.totalXP = totalXP
    self.milestones = milestones
    self.lastUpdated = lastUpdated
  }

  static let `default` = LevelData(
    milestones: [
      LevelMilestone(levelRequired: 5, title: "Early Adopter", description: "Reached level 5"),
      LevelMilestone(levelRequired: 10, title: "Fokus Meister", description: "Reached level 10"),
      LevelMilestone(levelRequired: 25, title: "Fokus Legende", description: "Reached level 25"),
    ]
  )
}
