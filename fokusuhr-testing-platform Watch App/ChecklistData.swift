import Foundation
import SwiftUI

struct EditableChecklistItem: Identifiable, Codable {
    var id = UUID()
    var title: String
    var imageName: String
    var colorName: String
    
    var color: Color {
        switch colorName {
        case "red": return .red
        case "blue": return .blue
        case "yellow": return .yellow
        case "purple": return .purple
        case "green": return .green
        case "pink": return .pink
        case "cyan": return .cyan
        case "orange": return .orange
        case "gray": return .gray
        case "brown": return .brown
        default: return .blue
        }
    }
    
    init(title: String, imageName: String, color: Color) {
        self.title = title
        self.imageName = imageName
        self.colorName = colorNameFromColor(color)
    }
}

private func colorNameFromColor(_ color: Color) -> String {
    switch color {
    case .red: return "red"
    case .blue: return "blue"
    case .yellow: return "yellow"
    case .purple: return "purple"
    case .green: return "green"    
    case .pink: return "pink"
    case .cyan: return "cyan"
    case .orange: return "orange"
    case .gray: return "gray"
    case .brown: return "brown"
    default: return "blue"
    }
}

struct ChecklistConfiguration: Codable {
    var bastelItems: [EditableChecklistItem]
    var rezeptItems: [EditableChecklistItem]
    
    static let `default` = ChecklistConfiguration(
        bastelItems: [
            EditableChecklistItem(title: "Eine Schere", imageName: "Schere", color: .red),
            EditableChecklistItem(title: "Ein Lineal", imageName: "Lineal", color: .blue),
            EditableChecklistItem(title: "Ein Bleistift", imageName: "Bleistift", color: .yellow),
            EditableChecklistItem(title: "Ein Leimstift", imageName: "Leimstift", color: .purple),
            EditableChecklistItem(title: "Buntes Papier", imageName: "Buntes Papier", color: .green),
            EditableChecklistItem(title: "Wolle", imageName: "Wolle", color: .pink),
            EditableChecklistItem(title: "Wackelaugen", imageName: "Wackelaugen", color: .cyan),
            EditableChecklistItem(title: "Locher", imageName: "Locher", color: .orange)
        ],
        rezeptItems: [
            EditableChecklistItem(title: "100g Zucker", imageName: "Zucker", color: .gray),
            EditableChecklistItem(title: "1 Ei", imageName: "Ei", color: .yellow),
            EditableChecklistItem(title: "100g Haselnüsse", imageName: "Haselnüsse", color: .brown),
            EditableChecklistItem(title: "75g Schokoladenpulver", imageName: "Schokoladenpulver", color: .brown),
            EditableChecklistItem(title: "1 EL Maizena", imageName: "Maizena", color: .orange),
            EditableChecklistItem(title: "1 Schüssel", imageName: "Schüssel", color: .blue),
            EditableChecklistItem(title: "1 Kelle", imageName: "Kelle", color: .gray),
            EditableChecklistItem(title: "1 Backblech", imageName: "Backblech", color: .gray),
            EditableChecklistItem(title: "1 Backpapier", imageName: "Backpapier", color: .gray),
            EditableChecklistItem(title: "1 Waage", imageName: "Waage", color: .green),
            EditableChecklistItem(title: "1 Messlöffel", imageName: "Messlöffel", color: .purple),
            EditableChecklistItem(title: "2 Topflappen", imageName: "Topflappen", color: .red)
        ]
    )
}
