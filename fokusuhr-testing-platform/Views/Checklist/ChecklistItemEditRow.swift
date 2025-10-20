import PhotosUI
import SwiftUI

struct ChecklistItemEditRow: View {
  @State var item: ChecklistItem
  @Binding var checklist: Checklist
  @ObservedObject var checklistManager: ChecklistManager
  @ObservedObject var galleryStorage: GalleryStorage

  var body: some View {
    HStack(spacing: 12) {
      if !item.imageName.isEmpty, let image = getImage() {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
          .frame(width: 44, height: 44)
          .clipShape(RoundedRectangle(cornerRadius: 8))
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
          )
      }

      VStack(alignment: .leading, spacing: 4) {
        TextField("Item title", text: $item.title)
          .font(.body)
          .onSubmit {
            updateItem()
          }

        Menu {
          Button("None") {
            item.imageName = ""
            updateItem()
          }

          Divider()

          ForEach(availableImages, id: \.self) { imageName in
            Button(imageName) {
              item.imageName = imageName
              updateItem()
            }
          }
        } label: {
          HStack(spacing: 4) {
            Image(systemName: "photo")
              .font(.caption2)
            Text(item.imageName.isEmpty ? "Add image" : item.imageName)
              .font(.caption)
            Image(systemName: "chevron.down")
              .font(.caption2)
          }
          .foregroundColor(.secondary)
        }
      }

      Spacer()
    }
    .padding(.vertical, 4)
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
      checklistManager.updateChecklist(checklist)
    }
  }
}
