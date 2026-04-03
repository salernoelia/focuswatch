import Combine
import Foundation
import WatchConnectivity

class GalleryManager: ObservableObject {

    static let shared = GalleryManager()

    @Published private(set) var receivedImages: Set<String> = []
    @Published private(set) var pendingAcknowledgments: [String] = []

    private var receivedImageHashes: Set<String> = []
    private let receivedHashesKey = "receivedImageHashes"
    private let receivedImagesKey = "receivedImageNames"
    private var lastImageDataHash: Int = 0
    private var acknowledgmentTimer: Timer?
    private let acknowledgmentBatchDelay: TimeInterval = 2.0

    init() {
        loadReceivedHashes()
        loadReceivedImages()
    }

    func clearOldGalleryImages() {
        guard
            let documentsPath = FileManager.default.urls(
                for: .documentDirectory, in: .userDomainMask
            ).first
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
                            AppError.fileOperationFailed(
                                operation: "remove old image", underlying: error))
                    #endif
                }
            }
        } catch {
            #if DEBUG
                ErrorLogger.log(
                    AppError.fileOperationFailed(
                        operation: "list directory contents", underlying: error))
            #endif
        }

        receivedImageHashes.removeAll()
        receivedImages.removeAll()
        lastImageDataHash = 0
        saveReceivedHashes()
        saveReceivedImages()
    }

    func saveGalleryImages(_ imageData: [String: Data]) {
        #if DEBUG
            print(
                "Watch GalleryManager: Received \(imageData.count) images via applicationContext: \(imageData.keys.sorted())"
            )
        #endif

        guard !imageData.isEmpty else {
            #if DEBUG
                print("Watch GalleryManager: No images to save")
            #endif
            return
        }

        let newHash = computeImageDataHash(imageData)

        if newHash == lastImageDataHash && lastImageDataHash != 0 {
            #if DEBUG
                print(
                    "Watch GalleryManager: Image data unchanged (hash: \(newHash)), skipping sync")
            #endif
            return
        }

        #if DEBUG
            print(
                "Watch GalleryManager: Processing images (hash: \(lastImageDataHash) -> \(newHash))"
            )
        #endif

        guard
            let documentsPath = FileManager.default.urls(
                for: .documentDirectory, in: .userDomainMask
            ).first
        else {
            #if DEBUG
                ErrorLogger.log(AppError.fileNotFound(path: "documents directory"))
            #endif
            return
        }

        var savedCount = 0
        var skippedCount = 0
        var savedImageNames: [String] = []

        for (imageName, imageBytes) in imageData {
            let data = imageBytes

            let imageURL = documentsPath.appendingPathComponent("\(imageName).jpg")

            if FileManager.default.fileExists(atPath: imageURL.path),
                let existingData = try? Data(contentsOf: imageURL),
                existingData.count == data.count
            {
                skippedCount += 1
                receivedImages.insert(imageName)
                continue
            }

            do {
                try data.write(to: imageURL)
                savedCount += 1
                savedImageNames.append(imageName)
                receivedImages.insert(imageName)
                #if DEBUG
                    print("Watch GalleryManager: Saved \(imageName) (\(data.count) bytes)")
                #endif
            } catch {
                #if DEBUG
                    print("Watch GalleryManager: Failed to save \(imageName): \(error)")
                    ErrorLogger.log(
                        AppError.fileOperationFailed(
                            operation: "save gallery image", underlying: error))
                #endif
            }
        }

        lastImageDataHash = newHash
        saveReceivedImages()

        #if DEBUG
            print(
                "Watch GalleryManager: Saved \(savedCount), skipped \(skippedCount) unchanged images"
            )
            print("Watch GalleryManager: receivedImages now contains: \(receivedImages.sorted())")
        #endif

        if !savedImageNames.isEmpty {
            scheduleAcknowledgment(for: savedImageNames)
        }
    }

    private func computeImageDataHash(_ imageData: [String: Data]) -> Int {
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
            let imageName = metadata[SyncConstants.Keys.imageName] as? String
        else {
            #if DEBUG
                ErrorLogger.log(
                    AppError.decodingFailed(
                        type: "file metadata",
                        underlying: NSError(domain: "GalleryManager", code: -1)))
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
            receivedImages.insert(imageName)
            scheduleAcknowledgment(for: [imageName])
            return
        }

        guard
            let documentsPath = FileManager.default.urls(
                for: .documentDirectory, in: .userDomainMask
            ).first
        else {
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

            receivedImages.insert(imageName)
            saveReceivedImages()

            scheduleAcknowledgment(for: [imageName])

            #if DEBUG
                print("Watch GalleryManager: SUCCESS - Saved file transfer image: \(imageName)")
            #endif
        } catch {
            #if DEBUG
                ErrorLogger.log(
                    AppError.fileOperationFailed(
                        operation: "save transferred image", underlying: error))
                print(
                    "Watch GalleryManager: FAILED to save \(imageName): \(error.localizedDescription)"
                )
            #endif
        }
    }

    private func scheduleAcknowledgment(for imageNames: [String]) {
        pendingAcknowledgments.append(contentsOf: imageNames)

        acknowledgmentTimer?.invalidate()
        acknowledgmentTimer = Timer.scheduledTimer(
            withTimeInterval: acknowledgmentBatchDelay, repeats: false
        ) { [weak self] _ in
            self?.sendAcknowledgments()
        }
    }

    private func sendAcknowledgments() {
        guard !pendingAcknowledgments.isEmpty else { return }

        let imagesToAcknowledge = pendingAcknowledgments
        pendingAcknowledgments.removeAll()

        let message: [String: Any] = [
            SyncConstants.Keys.action: SyncConstants.Actions.acknowledgeImages,
            SyncConstants.Keys.receivedImages: imagesToAcknowledge,
            SyncConstants.Keys.timestamp: Date().timeIntervalSince1970,
        ]

        #if DEBUG
            print(
                "Watch GalleryManager: Sending acknowledgment for \(imagesToAcknowledge.count) images"
            )
        #endif

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil) { [weak self] error in
                #if DEBUG
                    print(
                        "Watch GalleryManager: Acknowledgment failed: \(error.localizedDescription)"
                    )
                #endif
                self?.pendingAcknowledgments.append(contentsOf: imagesToAcknowledge)
            }
        } else {
            do {
                WCSession.default.transferUserInfo(message)
            }
        }
    }

    func imageExists(_ imageName: String) -> Bool {
        guard !imageName.isEmpty else { return true }

        guard
            let documentsPath = FileManager.default.urls(
                for: .documentDirectory, in: .userDomainMask
            ).first
        else {
            return false
        }

        let imageURL = documentsPath.appendingPathComponent("\(imageName).jpg")
        return FileManager.default.fileExists(atPath: imageURL.path)
    }

    func validateChecklistImages(_ checklist: Checklist) -> (valid: Bool, missingImages: [String]) {
        var missingImages: [String] = []

        for item in checklist.items {
            if !item.imageName.isEmpty && !imageExists(item.imageName) {
                missingImages.append(item.imageName)
            }
        }

        return (missingImages.isEmpty, missingImages)
    }

    func requestMissingImages(_ imageNames: [String]) {
        guard !imageNames.isEmpty else { return }

        let message: [String: Any] = [
            SyncConstants.Keys.action: SyncConstants.Actions.requestMissingImages,
            SyncConstants.Keys.missingImages: imageNames,
            SyncConstants.Keys.timestamp: Date().timeIntervalSince1970,
        ]

        #if DEBUG
            print(
                "Watch GalleryManager: Requesting \(imageNames.count) missing images: \(imageNames)"
            )
        #endif

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: nil)
        } else {
            WCSession.default.transferUserInfo(message)
        }
    }

    func reportSyncStatus(requiredImages: Set<String>) {
        let existingImages = requiredImages.filter { imageExists($0) }
        let missingImages = requiredImages.subtracting(existingImages)

        let status: String
        if missingImages.isEmpty {
            status = SyncConstants.Status.complete
        } else if existingImages.isEmpty {
            status = SyncConstants.Status.failed
        } else {
            status = SyncConstants.Status.partial
        }

        let message: [String: Any] = [
            SyncConstants.Keys.action: SyncConstants.Actions.reportSyncStatus,
            SyncConstants.Keys.syncStatus: status,
            SyncConstants.Keys.receivedImages: Array(existingImages),
            SyncConstants.Keys.missingImages: Array(missingImages),
            SyncConstants.Keys.timestamp: Date().timeIntervalSince1970,
        ]

        #if DEBUG
            print(
                "Watch GalleryManager: Reporting sync status: \(status) (received: \(existingImages.count), missing: \(missingImages.count))"
            )
        #endif

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: nil)
        }
    }

    private func loadReceivedHashes() {
        if let data = UserDefaults.standard.data(forKey: receivedHashesKey),
            let hashes = try? JSONDecoder().decode(Set<String>.self, from: data)
        {
            receivedImageHashes = hashes
        }
    }

    private func saveReceivedHashes() {
        if let data = try? JSONEncoder().encode(receivedImageHashes) {
            UserDefaults.standard.set(data, forKey: receivedHashesKey)
        }
    }

    private func loadReceivedImages() {
        if let data = UserDefaults.standard.data(forKey: receivedImagesKey),
            let images = try? JSONDecoder().decode(Set<String>.self, from: data)
        {
            receivedImages = images
        }
    }

    private func saveReceivedImages() {
        if let data = try? JSONEncoder().encode(receivedImages) {
            UserDefaults.standard.set(data, forKey: receivedImagesKey)
        }
    }
}
