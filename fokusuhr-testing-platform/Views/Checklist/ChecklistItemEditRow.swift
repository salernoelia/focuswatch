import SwiftUI
import PhotosUI

struct ChecklistItemEditRow: View {
    @State var item: ChecklistItem
    @Binding var checklist: Checklist
    @ObservedObject var checklistManager: ChecklistManager
    @ObservedObject var galleryStorage: GalleryStorage
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                TextField("Item title", text: $item.title)
                    .onSubmit {
                        updateItem()
                    }
                
                Menu("Image: \(item.imageName.isEmpty ? "None" : item.imageName)") {
                    Button("None") {
                        item.imageName = ""
                        updateItem()
                    }
                    
                    ForEach(availableImages, id: \.self) { imageName in
                        Button(imageName) {
                            item.imageName = imageName
                            updateItem()
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
    
    private func updateItem() {
        if let index = checklist.items.firstIndex(where: { $0.id == item.id }) {
            checklist.items[index] = item
            checklistManager.updateChecklist(checklist)
        }
    }
}