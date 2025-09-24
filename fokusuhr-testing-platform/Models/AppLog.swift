//
//  AppLog.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 24.09.2025.
//

import Foundation

struct AppLog: Identifiable, Codable {
    let id: Int
    let created_at: String
    let app_id: Int?
    let app_name: String?
    let data: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case id, created_at, app_id, app_name, data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        created_at = try container.decode(String.self, forKey: .created_at)
        app_id = try container.decodeIfPresent(Int.self, forKey: .app_id)
        app_name = try container.decodeIfPresent(String.self, forKey: .app_name)
        data = try container.decodeIfPresent([String: Any].self, forKey: .data)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(created_at, forKey: .created_at)
        try container.encodeIfPresent(app_id, forKey: .app_id)
        try container.encodeIfPresent(app_name, forKey: .app_name)
        try container.encodeIfPresent(data, forKey: .data)
    }
}