import Foundation
import SwiftUI

struct ChecklistItem: Identifiable, Codable {
    var id: UUID
    var title: String
    var imageName: String
    
    init(id: UUID = UUID(), title: String, imageName: String = "") {
        self.id = id
        self.title = title
        self.imageName = imageName
    }
}

struct Checklist: Identifiable, Codable {
    var id: UUID
    var name: String
    var items: [ChecklistItem]
    
    init(id: UUID = UUID(), name: String, items: [ChecklistItem] = []) {
        self.id = id
        self.name = name
        self.items = items
    }
}

struct ChecklistData: Codable {
    var checklists: [Checklist]
}

extension ChecklistItem {
    init(from model: ChecklistItemModel) {
        self.id = model.id
        self.title = model.title
        self.imageName = model.imageName
    }
}

extension Checklist {
    init(from model: ChecklistModel) {
        self.id = model.id
        self.name = model.name
        self.items = model.items.map { ChecklistItem(from: $0) }
    }
}

extension ChecklistData {
    init(from models: [ChecklistModel]) {
        self.checklists = models.map { Checklist(from: $0) }
    }
    
    static func getDefault() -> [ChecklistModel] {
        return [
            ChecklistModel(
                name: "Bastelsachen",
                items: [
                    ChecklistItemModel(title: "Eine Schere", imageName: "Schere"),
                    ChecklistItemModel(title: "Ein Lineal", imageName: "Lineal"),
                    ChecklistItemModel(title: "Ein Bleistift", imageName: "Bleistift"),
                    ChecklistItemModel(title: "Ein Leimstift", imageName: "Leimstift"),
                    ChecklistItemModel(title: "Buntes Papier", imageName: "Buntes Papier"),
                    ChecklistItemModel(title: "Wolle", imageName: "Wolle"),
                    ChecklistItemModel(title: "Wackelaugen", imageName: "Wackelaugen"),
                    ChecklistItemModel(title: "Locher", imageName: "Locher")
                ]
            ),
            ChecklistModel(
                name: "Schoggikugeln",
                items: [
                    ChecklistItemModel(title: "100g Zucker", imageName: "Zucker"),
                    ChecklistItemModel(title: "1 Ei", imageName: "Ei"),
                    ChecklistItemModel(title: "100g Haselnüsse", imageName: "Haselnüsse"),
                    ChecklistItemModel(title: "75g Schokoladenpulver", imageName: "Schokoladenpulver"),
                    ChecklistItemModel(title: "1 EL Maizena", imageName: "Maizena"),
                    ChecklistItemModel(title: "1 Schüssel", imageName: "Schüssel"),
                    ChecklistItemModel(title: "1 Kelle", imageName: "Kelle"),
                    ChecklistItemModel(title: "1 Backblech", imageName: "Backblech"),
                    ChecklistItemModel(title: "1 Backpapier", imageName: "Backpapier"),
                    ChecklistItemModel(title: "1 Waage", imageName: "Waage"),
                    ChecklistItemModel(title: "1 Messlöffel", imageName: "Messlöffel"),
                    ChecklistItemModel(title: "2 Topflappen", imageName: "Topflappen")
                ]
            )
        ]
    }
}
