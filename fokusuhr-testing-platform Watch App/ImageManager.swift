import Foundation
import UIKit

class ImageManager {
    static let shared = ImageManager()
    
    private let documentsDirectory: URL
    
    private init() {
        documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    func saveImage(_ image: UIImage, withName name: String) -> Bool {
        guard let data = image.pngData() else { return false }
        
        let url = documentsDirectory.appendingPathComponent("\(name).png")
        
        do {
            try data.write(to: url)
            return true
        } catch {
            print("Error saving image: \(error)")
            return false
        }
    }
    
    func loadImage(named name: String) -> UIImage? {
        let url = documentsDirectory.appendingPathComponent("\(name).png")
        return UIImage(contentsOfFile: url.path)
    }
    
    func deleteImage(named name: String) -> Bool {
        let url = documentsDirectory.appendingPathComponent("\(name).png")
        
        do {
            try FileManager.default.removeItem(at: url)
            return true
        } catch {
            print("Error deleting image: \(error)")
            return false
        }
    }
    
    func imageExists(named name: String) -> Bool {
        let url = documentsDirectory.appendingPathComponent("\(name).png")
        return FileManager.default.fileExists(atPath: url.path)
    }
}
