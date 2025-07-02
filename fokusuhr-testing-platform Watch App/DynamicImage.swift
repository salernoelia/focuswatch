import SwiftUI
import UIKit

struct DynamicImage: View {
    let imageName: String
    
    private let builtInImages = [
        "Schere", "Lineal", "Bleistift", "Leimstift", "Buntes Papier", "Wolle", 
        "Wackelaugen", "Locher", "Zucker", "Ei", "Haselnüsse", "Schokoladenpulver",
        "Maizena", "Schüssel", "Kelle", "Backblech", "Backpapier", "Waage",
        "Messlöffel", "Topflappen"
    ]
    
    var body: some View {
        Group {
            if builtInImages.contains(imageName) {
                if let _ = UIImage(named: imageName) {
                    Image(imageName)
                        .resizable()
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .foregroundColor(.gray)
                }
            } else if let uiImage = ImageManager.shared.loadImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .foregroundColor(.gray)
            }
        }
    }
}
