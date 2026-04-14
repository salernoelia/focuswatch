import Foundation

@MainActor
final class IncomingFileHandler {
    private let galleryManager: GalleryManager

    init(galleryManager: GalleryManager) {
        self.galleryManager = galleryManager
    }

    func handle(fileURL: URL, metadata: [String: Any]?) {
        #if DEBUG
            print("Watch SyncCoordinator: Received file transfer at: \(fileURL.path)")
            print("Watch SyncCoordinator: Metadata: \(String(describing: metadata))")
            if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
                let fileSize = attributes[.size] as? Int64
            {
                print("Watch SyncCoordinator: File size: \(fileSize) bytes")
            }
        #endif

        guard let metadata = metadata,
            let syncType = metadata[SyncConstants.Keys.syncType] as? String
        else {
            #if DEBUG
                print("Watch SyncCoordinator: No syncType in metadata, ignoring")
            #endif
            return
        }

        #if DEBUG
            print("Watch SyncCoordinator: SyncType: \(syncType)")
            if let imageName = metadata[SyncConstants.Keys.imageName] as? String {
                print("Watch SyncCoordinator: Image name: \(imageName)")
            }
        #endif

        switch syncType {
        case SyncMessageType.checklist.rawValue:
            galleryManager.handleReceivedFile(fileURL: fileURL, metadata: metadata)
        default:
            #if DEBUG
                print("Watch SyncCoordinator: Unknown syncType: \(syncType)")
            #endif
        }
    }
}
