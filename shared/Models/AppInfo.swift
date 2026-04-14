import Combine
import Foundation
import SwiftUI

struct AppInfo: Identifiable, Codable {
    let id = UUID()
    let title: String
    let emoji: String
    let description: String
    let color: Color
    let index: Int
    let symbol: String

    enum CodingKeys: String, CodingKey {
        case title, emoji, description, index
    }

    init(title: String, emoji: String = "", description: String, color: Color, index: Int = 0, symbol: String = "") {
        self.title = title
        self.emoji = emoji
        self.description = description
        self.color = color
        self.index = index
        self.symbol = symbol
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        emoji = try container.decodeIfPresent(String.self, forKey: .emoji) ?? ""
        description = try container.decode(String.self, forKey: .description)
        index = try container.decodeIfPresent(Int.self, forKey: .index) ?? 0
        color = .blue
        symbol = ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(emoji, forKey: .emoji)
        try container.encode(description, forKey: .description)
        try container.encode(index, forKey: .index)
    }
}
