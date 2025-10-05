import PhotosUI
import SwiftUI

class GalleryStorage: ObservableObject {
  @Published var items: [GalleryItem] = []

  static let shared = GalleryStorage()

  private init() {
    loadItems()
  }

  func addItem(image: UIImage, label: String) {
    let imageName = "\(UUID().uuidString).jpg"

    guard
      let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        .first
    else {
      #if DEBUG
        ErrorLogger.log(.fileNotFound(path: "documents directory"))
      #endif
      return
    }

    let url = documentsURL.appendingPathComponent(imageName)

    let resizedImage = resizeImage(image, targetSize: AppConstants.Image.thumbnailSize)

    guard
      let data = resizedImage.jpegData(compressionQuality: AppConstants.Image.compressionQuality)
    else {
      #if DEBUG
        ErrorLogger.log(
          .encodingFailed(
            type: "image", underlying: NSError(domain: "GalleryStorage", code: -1, userInfo: nil)))
      #endif
      return
    }

    do {
      try data.write(to: url)
      let item = GalleryItem(imagePath: imageName, label: label)
      items.append(item)
      saveItems()
    } catch {
      #if DEBUG
        ErrorLogger.log(.fileOperationFailed(operation: "save image", underlying: error))
      #endif
    }
  }

  func deleteItem(_ item: GalleryItem) {
    guard
      let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        .first
    else {
      #if DEBUG
        ErrorLogger.log(.fileNotFound(path: "documents directory"))
      #endif
      return
    }

    let url = documentsURL.appendingPathComponent(item.imagePath)

    if FileManager.default.fileExists(atPath: url.path) {
      do {
        try FileManager.default.removeItem(at: url)
      } catch {
        #if DEBUG
          ErrorLogger.log(.fileOperationFailed(operation: "delete image", underlying: error))
        #endif
      }
    }

    items.removeAll { $0.id == item.id }
    saveItems()
  }

  func deleteItems(at offsets: IndexSet) {
    guard
      let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        .first
    else {
      #if DEBUG
        ErrorLogger.log(.fileNotFound(path: "documents directory"))
      #endif
      return
    }

    for index in offsets {
      let item = items[index]
      let url = documentsURL.appendingPathComponent(item.imagePath)

      if FileManager.default.fileExists(atPath: url.path) {
        do {
          try FileManager.default.removeItem(at: url)
        } catch {
          #if DEBUG
            ErrorLogger.log(.fileOperationFailed(operation: "delete image", underlying: error))
          #endif
        }
      }
    }

    items.remove(atOffsets: offsets)
    saveItems()
  }

  private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
    let size = image.size

    let widthRatio = targetSize.width / size.width
    let heightRatio = targetSize.height / size.height

    let newSize =
      widthRatio > heightRatio
      ? CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
      : CGSize(width: size.width * widthRatio, height: size.height * widthRatio)

    let rect = CGRect(origin: .zero, size: newSize)

    UIGraphicsBeginImageContextWithOptions(newSize, false, AppConstants.Image.renderingScale)
    image.draw(in: rect)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return newImage ?? image
  }

  private func saveItems() {
    do {
      let data = try JSONEncoder().encode(items)
      UserDefaults.standard.set(data, forKey: "galleryItems")
    } catch {
      #if DEBUG
        ErrorLogger.log(.encodingFailed(type: "gallery items", underlying: error))
      #endif
    }
  }

  private func loadItems() {
    guard let data = UserDefaults.standard.data(forKey: "galleryItems") else { return }

    do {
      items = try JSONDecoder().decode([GalleryItem].self, from: data)
    } catch {
      #if DEBUG
        ErrorLogger.log(.decodingFailed(type: "gallery items", underlying: error))
      #endif
    }
  }

  func updateItemLabel(_ item: GalleryItem, newLabel: String) {
    if let index = items.firstIndex(where: { $0.id == item.id }) {
      items[index].label = newLabel
      saveItems()
    }
  }
}
