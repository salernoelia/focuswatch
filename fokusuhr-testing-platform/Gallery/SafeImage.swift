import SwiftUI

struct SafeImage: View {
    let imageName: String
    
    var body: some View {
        Group {
            if let _ = UIImage(named: imageName) {
                Image(imageName)
                    .resizable()
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .foregroundColor(.gray)
            }
        }
    }
}
