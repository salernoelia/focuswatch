import Foundation
import SwiftData
import UIKit

@Model
final class GalleryItemModel {
    var id: UUID
    var imagePath: String
    var label: String
    var createdAt: Date
    
    init(id: UUID = UUID(), imagePath: String, label: String, createdAt: Date = Date()) {
        self.id = id
        self.imagePath = imagePath
        self.label = label
        self.createdAt = createdAt
    }
    
    var image: UIImage? {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(imagePath)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}
