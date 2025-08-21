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
        
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: url)
            let item = GalleryItem(imagePath: imageName, label: label)
            items.append(item)
            saveItems()
        }
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