import Foundation

class GalleryManager {

    static let shared = GalleryManager()

    private var receivedImageHashes: Set<String> = []
    private let receivedHashesKey = "receivedImageHashes"
    private var lastImageDataHash: Int = 0

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
        lastImageDataHash = 0
        saveReceivedHashes()
    }

    func saveGalleryImages(_ imageData: [String: String]) {
        #if DEBUG
            print("Watch GalleryManager: Received \(imageData.count) images via applicationContext")
        #endif

        guard !imageData.isEmpty else { return }

        let newHash = computeImageDataHash(imageData)
        
        if newHash == lastImageDataHash && lastImageDataHash != 0 {
            #if DEBUG
                print("Watch GalleryManager: Image data unchanged (hash: \(newHash)), skipping sync")
            #endif
            return
        }

        #if DEBUG
            print("Watch GalleryManager: Processing images (hash: \(lastImageDataHash) -> \(newHash))")
        #endif

        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            #if DEBUG
                ErrorLogger.log(AppError.fileNotFound(path: "documents directory"))
            #endif
            return
        }

        var savedCount = 0
        var skippedCount = 0

        for (imageName, base64String) in imageData {
            guard let data = Data(base64Encoded: base64String) else {
                #if DEBUG
                    ErrorLogger.log(AppError.decodingFailed(type: "base64 image", underlying: NSError(domain: "GalleryManager", code: -1)))
                #endif
                continue
            }

            let imageURL = documentsPath.appendingPathComponent("\(imageName).jpg")
            
            if FileManager.default.fileExists(atPath: imageURL.path),
               let existingData = try? Data(contentsOf: imageURL),
               existingData.count == data.count {
                skippedCount += 1
                continue
            }

            do {
                try data.write(to: imageURL)
                savedCount += 1
            } catch {
                #if DEBUG
                    ErrorLogger.log(AppError.fileOperationFailed(operation: "save gallery image", underlying: error))
                #endif
            }
        }

        lastImageDataHash = newHash

        #if DEBUG
            print("Watch GalleryManager: Saved \(savedCount), skipped \(skippedCount) unchanged images")
        #endif
    }

    private func computeImageDataHash(_ imageData: [String: String]) -> Int {
        var hasher = Hasher()
        for key in imageData.keys.sorted() {
            hasher.combine(key)
            hasher.combine(imageData[key]?.count ?? 0)
        }
        return hasher.finalize()
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
