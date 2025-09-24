//
//  App.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 24.09.2025.
//

import Foundation

struct App: Identifiable, Codable {
    let id: Int
    let created_at: String
    let name: String
    let data: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case id, created_at, name, data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        created_at = try container.decode(String.self, forKey: .created_at)
        name = try container.decode(String.self, forKey: .name)
        data = try container.decodeIfPresent([String: Any].self, forKey: .data)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(created_at, forKey: .created_at)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(data, forKey: .data)
    }
}