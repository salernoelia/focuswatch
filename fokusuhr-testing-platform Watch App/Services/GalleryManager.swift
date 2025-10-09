import Foundation

class GalleryManager {

  static let shared = GalleryManager()

  func clearOldGalleryImages() {
    guard
      let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        .first
    else {
      #if DEBUG
        ErrorLogger.log(AppError.fileNotFound(path: "documents directory"))
      #endif
      return
    }

    do {
      let contents = try FileManager.default.contentsOfDirectory(
        at: documentsPath, includingPropertiesForKeys: nil)

      for fileURL in contents where fileURL.pathExtension == "jpg" {
        do {
          try FileManager.default.removeItem(at: fileURL)
          #if DEBUG
            ErrorLogger.log("Removed old image: \(fileURL.lastPathComponent)")
          #endif
        } catch {
          #if DEBUG
            ErrorLogger.log(
              AppError.fileOperationFailed(operation: "remove old image", underlying: error))
          #endif
        }
      }
    } catch {
      let appError = AppError.fileOperationFailed(
        operation: "list directory contents", underlying: error)
      #if DEBUG
        ErrorLogger.log(appError)
      #endif
    }
  }

  func saveGalleryImages(_ imageData: [String: String]) {
    guard
      let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        .first
    else {
      #if DEBUG
        ErrorLogger.log(AppError.fileNotFound(path: "documents directory"))
      #endif
      return
    }

    for (imageName, base64String) in imageData {
      guard let data = Data(base64Encoded: base64String) else {
        #if DEBUG
          ErrorLogger.log(
            AppError.decodingFailed(
              type: "base64 image", underlying: NSError(domain: "GalleryManager", code: -1)))
        #endif
        continue
      }

      let imageURL = documentsPath.appendingPathComponent("\(imageName).jpg")
      do {
        try data.write(to: imageURL)
      } catch {
        let appError = AppError.fileOperationFailed(
          operation: "save gallery image", underlying: error)
        #if DEBUG
          ErrorLogger.log(appError)
        #endif
      }
    }
  }
}
