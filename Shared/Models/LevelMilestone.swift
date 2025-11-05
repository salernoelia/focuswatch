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
            LevelMilestone(
                levelRequired: 3,
                title: String(localized: "Early Bird"),
                description: String(localized: "Reached Level 5")
            ),
            LevelMilestone(
                levelRequired: 5,
                title: String(localized: "Focus Trainee"),
                description: String(localized: "Reached Level 5")
            ),
            LevelMilestone(
                levelRequired: 10,
                title: String(localized: "Focus Master"),
                description: "Reached level 10"
            ),
            LevelMilestone(
                levelRequired: 15,
                title: String(localized: "Focus Champion"),
                description: "Reached level 15"
            ),
            LevelMilestone(
                levelRequired: 20,
                title: String(localized: "Hard Working"),
                description: "Reached level 20"
            ),
            LevelMilestone(
                levelRequired: 25,
                title: String(localized: "Focus Legend"),
                description: "Reached level 25"
            ),
        ]
    )
}
