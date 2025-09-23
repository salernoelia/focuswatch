//
//  AppInfo.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 23.09.2025.
//


import Foundation
import Combine
import SwiftUI

struct AppInfo: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let color: Color
    
    enum CodingKeys: String, CodingKey {
        case title, description
    }
    
    init(title: String, description: String, color: Color) {
        self.title = title
        self.description = description
        self.color = color
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        color = .blue // Default color when decoding
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
    }
}