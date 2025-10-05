import SwiftUI
import PhotosUI

struct ChecklistItemEditRow: View {
    @Bindable var item: ChecklistItemModel
    let checklist: ChecklistModel
    @ObservedObject var checklistManager: ChecklistManager
    @ObservedObject var galleryStorage: GalleryStorage
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                TextField("Item title", text: $item.title)
                    .onSubmit {
                        checklistManager.updateChecklist(checklist)
                    }
                
                Menu("Image: \(item.imageName.isEmpty ? "None" : item.imageName)") {
                    Button("None") {
                        item.imageName = ""
                        checklistManager.updateChecklist(checklist)
                    }
                    
                    ForEach(availableImages, id: \.self) { imageName in
                        Button(imageName) {
                            item.imageName = imageName
                            checklistManager.updateChecklist(checklist)
                        }
                    }
                }
                .font(.caption)
            }
            
            if !item.imageName.isEmpty {
                if UIImage(named: item.imageName) != nil {
                    Image(item.imageName)
                        .resizable()
                        .frame(width: 30, height: 30)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                } else {
                    Image(systemName: "photo")
                        .frame(width: 30, height: 30)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    private var availableImages: [String] {
        let watchImages = ["Schere", "Lineal", "Bleistift", "Leimstift", "Buntes Papier", "Wolle", "Wackelaugen", "Locher", "Zucker", "Ei", "Haselnüsse", "Schokoladenpulver", "Maizena", "Schüssel", "Kelle", "Backblech", "Backpapier", "Waage", "Messlöffel", "Topflappen"]
        let galleryImages = galleryStorage.items.map { $0.label }
        return galleryImages + watchImages.filter { UIImage(named: $0) != nil }
    }
}