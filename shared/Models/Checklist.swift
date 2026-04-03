import Foundation
import SwiftUI

enum ChecklistSwipeDirection: String, Codable {
    case left
    case right
}

enum ChecklistSwipeDirectionMapping: String, Codable, CaseIterable {
    case collectRightDelayLeft
    case collectLeftDelayRight

    var collectDirection: ChecklistSwipeDirection {
        switch self {
        case .collectRightDelayLeft:
            return .right
        case .collectLeftDelayRight:
            return .left
        }
    }

    var delayDirection: ChecklistSwipeDirection {
        switch self {
        case .collectRightDelayLeft:
            return .left
        case .collectLeftDelayRight:
            return .right
        }
    }
}

enum ChecklistResetInterval: String, Codable, CaseIterable {
    case none
    case daily
    case weekly
}

struct ChecklistResetConfiguration: Codable {
    var interval: ChecklistResetInterval
    var hour: Int
    var minute: Int
    var weekday: Int

    init(interval: ChecklistResetInterval = .none, hour: Int = 2, minute: Int = 0, weekday: Int = 2)
    {
        self.interval = interval
        self.hour = min(max(hour, 0), 23)
        self.minute = min(max(minute, 0), 59)
        self.weekday = min(max(weekday, 1), 7)
    }
}

struct ChecklistItem: Identifiable, Codable {
    var id = UUID()
    var title: String
    var imageName: String

    init(title: String, imageName: String = "") {
        self.title = title
        self.imageName = imageName
    }
}

struct Checklist: Identifiable, Codable {
    var id = UUID()
    var name: String
    var tag: String
    var description: String
    var items: [ChecklistItem]
    var xpReward: Int
    var resetConfiguration: ChecklistResetConfiguration
    var swipeMapping: ChecklistSwipeDirectionMapping

    init(
        name: String,
        tag: String = "",
        description: String = "",
        items: [ChecklistItem] = [],
        xpReward: Int = 50,
        resetConfiguration: ChecklistResetConfiguration = ChecklistResetConfiguration(),
        swipeMapping: ChecklistSwipeDirectionMapping = .collectRightDelayLeft
    ) {
        self.name = name
        self.tag = tag
        self.description = description
        self.items = items
        self.xpReward = xpReward
        self.resetConfiguration = resetConfiguration
        self.swipeMapping = swipeMapping
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case tag
        case description
        case items
        case xpReward
        case resetConfiguration
        case swipeMapping
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        tag = try container.decodeIfPresent(String.self, forKey: .tag) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        items = try container.decodeIfPresent([ChecklistItem].self, forKey: .items) ?? []
        xpReward = try container.decodeIfPresent(Int.self, forKey: .xpReward) ?? 50
        resetConfiguration =
            try container.decodeIfPresent(
                ChecklistResetConfiguration.self, forKey: .resetConfiguration)
            ?? ChecklistResetConfiguration()
        swipeMapping =
            try container.decodeIfPresent(
                ChecklistSwipeDirectionMapping.self, forKey: .swipeMapping)
            ?? .collectRightDelayLeft
    }
}

struct ChecklistData: Codable {
    var checklists: [Checklist]

    static let `default` = ChecklistData(
        checklists: [
            Checklist(
                name: "Bastelsachen",
                tag: "Schulroutinen",
                description: "Sammle alle benötigten Bastelmaterialien für dein Projekt.",
                items: [
                    ChecklistItem(title: "Eine Schere", imageName: "Schere"),
                    ChecklistItem(title: "Ein Lineal", imageName: "Lineal"),
                    ChecklistItem(title: "Ein Bleistift", imageName: "Bleistift"),
                    ChecklistItem(title: "Ein Leimstift", imageName: "Leimstift"),
                    ChecklistItem(title: "Buntes Papier", imageName: "Buntes Papier"),
                    ChecklistItem(title: "Wolle", imageName: "Wolle"),
                    ChecklistItem(title: "Wackelaugen", imageName: "Wackelaugen"),
                    ChecklistItem(title: "Locher", imageName: "Locher"),
                ]
            ),
            Checklist(
                name: "Schoggikugeln",
                tag: "Küche",
                description:
                    "Bereite alle Zutaten und Küchenutensilien für leckere Schoggikugeln vor.",
                items: [
                    ChecklistItem(title: "100g Zucker", imageName: "Zucker"),
                    ChecklistItem(title: "1 Ei", imageName: "Ei"),
                    ChecklistItem(title: "100g Haselnüsse", imageName: "Haselnüsse"),
                    ChecklistItem(title: "75g Schokoladenpulver", imageName: "Schokoladenpulver"),
                    ChecklistItem(title: "1 EL Maizena", imageName: "Maizena"),
                    ChecklistItem(title: "1 Schüssel", imageName: "Schüssel"),
                    ChecklistItem(title: "1 Kelle", imageName: "Kelle"),
                    ChecklistItem(title: "1 Backblech", imageName: "Backblech"),
                    ChecklistItem(title: "1 Backpapier", imageName: "Backpapier"),
                    ChecklistItem(title: "1 Waage", imageName: "Waage"),
                    ChecklistItem(title: "1 Messlöffel", imageName: "Messlöffel"),
                    ChecklistItem(title: "2 Topflappen", imageName: "Topflappen"),
                ]
            ),
        ]
    )
}
