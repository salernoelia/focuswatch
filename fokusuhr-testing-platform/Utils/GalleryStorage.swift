//
//  GalleryStorage.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 21.08.2025.
//


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
        
        let resizedImage = resizeImage(image, targetSize: CGSize(width: 150, height: 150))
        
        if let data = resizedImage.jpegData(compressionQuality: 0.2) {
            try? data.write(to: url)
            let item = GalleryItem(imagePath: imageName, label: label)
            items.append(item)
            saveItems()
        }
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
}
