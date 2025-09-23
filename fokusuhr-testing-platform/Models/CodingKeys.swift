//
//  CodingKeys.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 23.09.2025.
//


import Foundation
import Combine
import SwiftUI

extension Color: Codable {
    enum CodingKeys: String, CodingKey {
        case red, green, blue, alpha
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let red = try container.decode(Double.self, forKey: .red)
        let green = try container.decode(Double.self, forKey: .green)
        let blue = try container.decode(Double.self, forKey: .blue)
        let alpha = try container.decode(Double.self, forKey: .alpha)
        self.init(red: red, green: green, blue: blue, opacity: alpha)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(0.0, forKey: .red)
        try container.encode(0.0, forKey: .green)
        try container.encode(1.0, forKey: .blue)
        try container.encode(1.0, forKey: .alpha)
    }
}