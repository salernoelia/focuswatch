import Foundation

class GalleryManager {

    static let shared = GalleryManager()

    private var receivedImageHashes: Set<String> = []
    private let receivedHashesKey = "receivedImageHashes"

    init() {
        loadReceivedHashes()
    }

    func clearOldGalleryImages() {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            #if DEBUG
                ErrorLogger.log(AppError.fileNotFound(path: "documents directory"))
            #endif
            return
        }

        do {
            let contents = try FileManager.default.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: nil)

            for fileURL in contents where fileURL.pathExtension == "jpg" {
                do {
                    try FileManager.default.removeItem(at: fileURL)
                    #if DEBUG
                        ErrorLogger.log("Removed old image: \(fileURL.lastPathComponent)")
                    #endif
                } catch {
                    #if DEBUG
                        ErrorLogger.log(AppError.fileOperationFailed(operation: "remove old image", underlying: error))
                    #endif
                }
            }
        } catch {
            #if DEBUG
                ErrorLogger.log(AppError.fileOperationFailed(operation: "list directory contents", underlying: error))
            #endif
        }

        receivedImageHashes.removeAll()
        saveReceivedHashes()
    }

    func saveGalleryImages(_ imageData: [String: String]) {
        #if DEBUG
            print("Watch GalleryManager: Received \(imageData.count) images via applicationContext")
        #endif

        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            #if DEBUG
                ErrorLogger.log(AppError.fileNotFound(path: "documents directory"))
            #endif
            return
        }

        for (imageName, base64String) in imageData {
            guard let data = Data(base64Encoded: base64String) else {
                #if DEBUG
                    ErrorLogger.log(AppError.decodingFailed(type: "base64 image", underlying: NSError(domain: "GalleryManager", code: -1)))
                    print("Watch GalleryManager: Failed to decode base64 for \(imageName)")
                #endif
                continue
            }

            let imageURL = documentsPath.appendingPathComponent("\(imageName).jpg")
            do {
                try data.write(to: imageURL)
                #if DEBUG
                    print("Watch GalleryManager: Saved image \(imageName) (\(data.count) bytes)")
                #endif
            } catch {
                #if DEBUG
                    ErrorLogger.log(AppError.fileOperationFailed(operation: "save gallery image", underlying: error))
                    print("Watch GalleryManager: Failed to save \(imageName): \(error.localizedDescription)")
                #endif
            }
        }
    }

    func handleReceivedFile(fileURL: URL, metadata: [String: Any]?) {
        #if DEBUG
            print("Watch GalleryManager: Received file transfer")
            print("Watch GalleryManager: File URL: \(fileURL)")
            print("Watch GalleryManager: Metadata: \(String(describing: metadata))")
        #endif

        guard let metadata = metadata,
              let imageName = metadata[SyncConstants.Keys.imageName] as? String else {
            #if DEBUG
                ErrorLogger.log(AppError.decodingFailed(type: "file metadata", underlying: NSError(domain: "GalleryManager", code: -1)))
                print("Watch GalleryManager: Missing imageName in metadata")
            #endif
            return
        }

        let imageHash = metadata[SyncConstants.Keys.imageHash] as? String ?? ""
        let hashKey = "\(imageName):\(imageHash)"

        if !imageHash.isEmpty && receivedImageHashes.contains(hashKey) {
            #if DEBUG
                print("Watch GalleryManager: Skipping duplicate image: \(imageName)")
            #endif
            return
        }

        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            #if DEBUG
                ErrorLogger.log(AppError.fileNotFound(path: "documents directory"))
                print("Watch GalleryManager: Cannot get documents path")
            #endif
            return
        }

        let destinationURL = documentsPath.appendingPathComponent("\(imageName).jpg")

        do {
            let sourceExists = FileManager.default.fileExists(atPath: fileURL.path)
            #if DEBUG
                print("Watch GalleryManager: Source file exists: \(sourceExists)")
            #endif

            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }

            try FileManager.default.copyItem(at: fileURL, to: destinationURL)

            if !imageHash.isEmpty {
                receivedImageHashes.insert(hashKey)
                saveReceivedHashes()
            }

            #if DEBUG
                print("Watch GalleryManager: SUCCESS - Saved file transfer image: \(imageName)")
            #endif
        } catch {
            #if DEBUG
                ErrorLogger.log(AppError.fileOperationFailed(operation: "save transferred image", underlying: error))
                print("Watch GalleryManager: FAILED to save \(imageName): \(error.localizedDescription)")
            #endif
        }
    }

    private func loadReceivedHashes() {
        if let data = UserDefaults.standard.data(forKey: receivedHashesKey),
           let hashes = try? JSONDecoder().decode(Set<String>.self, from: data) {
            receivedImageHashes = hashes
        }
    }

    private func saveReceivedHashes() {
        if let data = try? JSONEncoder().encode(receivedImageHashes) {
            UserDefaults.standard.set(data, forKey: receivedHashesKey)
        }
    }
}
