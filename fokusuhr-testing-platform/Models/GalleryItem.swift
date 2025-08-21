//
//  GalleryItem.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 21.08.2025.
//


import SwiftUI
import PhotosUI

struct GalleryItem: Identifiable, Codable {
    var id = UUID()
    let imagePath: String  // Changed from UIImage to file path
    let label: String
    
    var image: UIImage? {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(imagePath)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}