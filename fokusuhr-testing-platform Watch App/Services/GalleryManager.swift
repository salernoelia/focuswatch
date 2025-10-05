import Foundation

class GalleryManager {
    
    static let shared = GalleryManager()
    
    func clearOldGalleryImages() {
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask)[0]

        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: documentsPath, includingPropertiesForKeys: nil)

            for fileURL in contents {
                if fileURL.pathExtension == "jpg" {
                    try? FileManager.default.removeItem(at: fileURL)
                    print("Removed old image: \(fileURL.lastPathComponent)")
                }
            }
        } catch {
            print(
                "Error clearing old gallery images: \(error.localizedDescription)"
            )
        }
    }

    func saveGalleryImages(_ imageData: [String: String]) {
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask)[0]

        for (imageName, base64String) in imageData {
            if let data = Data(base64Encoded: base64String) {
                let imageURL = documentsPath.appendingPathComponent(
                    "\(imageName).jpg")
                try? data.write(to: imageURL)
            }
        }
    }
}
