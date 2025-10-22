import Combine
import Foundation
import SwiftUI

struct CodableColor: Codable {
  let color: Color

  enum CodingKeys: String, CodingKey {
    case red, green, blue, alpha
  }

  init(color: Color) {
    self.color = color
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let red = try container.decode(Double.self, forKey: .red)
    let green = try container.decode(Double.self, forKey: .green)
    let blue = try container.decode(Double.self, forKey: .blue)
    let alpha = try container.decode(Double.self, forKey: .alpha)
    self.color = Color(red: red, green: green, blue: blue, opacity: alpha)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0

    #if canImport(UIKit)
      UIColor(self.color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    #elseif canImport(AppKit)
      NSColor(self.color).usingColorSpace(.deviceRGB)?.getRed(
        &red, green: &green, blue: &blue, alpha: &alpha)
    #endif

    try container.encode(Double(red), forKey: .red)
    try container.encode(Double(green), forKey: .green)
    try container.encode(Double(blue), forKey: .blue)
    try container.encode(Double(alpha), forKey: .alpha)
  }
}
