import Foundation
import SwiftUI

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
  var description: String
  var items: [ChecklistItem]

  init(name: String, description: String = "", items: [ChecklistItem] = []) {
    self.name = name
    self.description = description
    self.items = items
  }
}

struct ChecklistData: Codable {
  var checklists: [Checklist]

  static let `default` = ChecklistData(
    checklists: [
      Checklist(
        name: "Bastelsachen",
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
        description: "Bereite alle Zutaten und Küchenutensilien für leckere Schoggikugeln vor.",
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
