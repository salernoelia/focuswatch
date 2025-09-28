import SwiftUI
import PhotosUI

class GalleryStorage: ObservableObject {
    @Published var items: [GalleryItem] = []
    
    init() {
        loadItems()
    }
    
    func addItem(image: UIImage, label: String) {
        let imageName = "\(UUID().uuidString).jpg"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(imageName)
        
        let resizedImage = resizeImage(image, targetSize: CGSize(width: 300, height: 300))
        
        if let data = resizedImage.jpegData(compressionQuality: 0.3) {
            try? data.write(to: url)
            let item = GalleryItem(imagePath: imageName, label: label)
            items.append(item)
            saveItems()
        }
    }
    
    func deleteItem(_ item: GalleryItem) {
    
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(item.imagePath)
        try? FileManager.default.removeItem(at: url)
        
        items.removeAll { $0.id == item.id }
        saveItems()
    }
    
    func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = items[index]
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(item.imagePath)
            try? FileManager.default.removeItem(at: url)
        }
        items.remove(atOffsets: offsets)
        saveItems()
    }
    
    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        let newSize = widthRatio > heightRatio ?
            CGSize(width: size.width * heightRatio, height: size.height * heightRatio) :
            CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        
        let rect = CGRect(origin: .zero, size: newSize)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
    
    private func saveItems() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: "galleryItems")
        }
    }
    
    private func loadItems() {
        guard let data = UserDefaults.standard.data(forKey: "galleryItems"),
              let decoded = try? JSONDecoder().decode([GalleryItem].self, from: data) else { return }
        items = decoded
    }

    func updateItemLabel(_ item: GalleryItem, newLabel: String) {
    if let index = items.firstIndex(where: { $0.id == item.id }) {
        items[index].label = newLabel
        saveItems()
    }
}
}
