import PhotosUI
import SwiftUI

struct ChecklistItemEditRow: View {
    @State var item: ChecklistItem
    @Binding var checklist: Checklist
    @ObservedObject var checklistService: ChecklistSyncService
    @ObservedObject var galleryStorage: GalleryStorage
    @State private var showingImageSelector = false

    var body: some View {
        HStack(spacing: 12) {
            Button {
                showingImageSelector = true
            } label: {
                if !item.imageName.isEmpty, let image = getImage() {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.secondary.opacity(0.1))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "photo.badge.plus")
                                .foregroundColor(.secondary)
                        )
                }
            }

            TextField(NSLocalizedString("Item title", comment: ""), text: $item.title)
                .font(.body)
                .onChange(of: item.title, initial: false) { _, _ in
                    updateItem()
                }

            Spacer()
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingImageSelector) {
            ImageSelectorView(
                currentImageName: item.imageName,
                galleryStorage: galleryStorage
            ) { selectedImageName in
                item.imageName = selectedImageName
                updateItem()
            }
        }
    }

    private var availableImages: [String] {
        let watchImages = [
            "Schere", "Lineal", "Bleistift", "Leimstift", "Buntes Papier", "Wolle", "Wackelaugen",
            "Locher", "Zucker", "Ei", "Haselnüsse", "Schokoladenpulver", "Maizena", "Schüssel", "Kelle",
            "Backblech", "Backpapier", "Waage", "Messlöffel", "Topflappen",
        ]
        let galleryImages = galleryStorage.items.map { $0.label }
        return galleryImages + watchImages.filter { UIImage(named: $0) != nil }
    }

    private func getImage() -> UIImage? {
        if let galleryItem = galleryStorage.items.first(where: { $0.label == item.imageName }) {
            return galleryItem.image
        }
        return UIImage(named: item.imageName)
    }

    private func updateItem() {
        if let index = checklist.items.firstIndex(where: { $0.id == item.id }) {
            checklist.items[index] = item
            var data = checklistService.checklistData
            if let checklistIndex = data.checklists.firstIndex(where: { $0.id == checklist.id }) {
                data.checklists[checklistIndex] = checklist
                checklistService.updateChecklistData(data)
            }
        }
    }
}
