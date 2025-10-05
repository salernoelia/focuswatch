import Foundation
import SwiftData

@Model
final class ChecklistItemModel {
    var id: UUID
    var title: String
    var imageName: String
    var checklist: ChecklistModel?
    
    init(id: UUID = UUID(), title: String, imageName: String = "") {
        self.id = id
        self.title = title
        self.imageName = imageName
    }
}

@Model
final class ChecklistModel {
    var id: UUID
    var name: String
    @Relationship(deleteRule: .cascade, inverse: \ChecklistItemModel.checklist)
    var items: [ChecklistItemModel]
    
    init(id: UUID = UUID(), name: String, items: [ChecklistItemModel] = []) {
        self.id = id
        self.name = name
        self.items = items
    }
}
