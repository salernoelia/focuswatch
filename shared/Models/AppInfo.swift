import Combine
import Foundation
import SwiftUI

enum WatchAppID: String, Codable, Hashable, CaseIterable {
    case checklists
    case calendar
    case level
    case meter
    case writing
    case pomodoro
    case fidget
    case breathing
    case settings

    static let defaultOrder: [WatchAppID] = [
        .checklists, .calendar, .level,
        .meter, .writing, .pomodoro, .fidget, .breathing
    ]
}

struct AppInfo: Identifiable, Codable, Hashable {
    let id: String
    let appID: WatchAppID?
    let title: String
    let emoji: String
    let description: String
    let color: Color
    let symbol: String
    let legacyIndex: Int

    enum CodingKeys: String, CodingKey {
        case title, emoji, description, index
    }

    init(
        appID: WatchAppID? = nil,
        title: String,
        emoji: String = "",
        description: String,
        color: Color,
        legacyIndex: Int = 0,
        symbol: String = ""
    ) {
        self.id = appID?.rawValue ?? UUID().uuidString
        self.appID = appID
        self.title = title
        self.emoji = emoji
        self.description = description
        self.color = color
        self.legacyIndex = legacyIndex
        self.symbol = symbol
    }

    init(checklistID: UUID, title: String, emoji: String, legacyIndex: Int) {
        self.id = checklistID.uuidString
        self.appID = nil
        self.title = title
        self.emoji = emoji
        self.description = String(localized: "Interaktive Checkliste")
        self.color = .blue
        self.legacyIndex = legacyIndex
        self.symbol = ""
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        emoji = try container.decodeIfPresent(String.self, forKey: .emoji) ?? ""
        description = try container.decode(String.self, forKey: .description)
        legacyIndex = try container.decodeIfPresent(Int.self, forKey: .index) ?? 0
        color = .blue
        symbol = ""
        appID = nil
        id = UUID().uuidString
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(emoji, forKey: .emoji)
        try container.encode(description, forKey: .description)
        try container.encode(legacyIndex, forKey: .index)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: AppInfo, rhs: AppInfo) -> Bool {
        lhs.id == rhs.id
    }
}
