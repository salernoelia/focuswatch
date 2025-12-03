import Combine
import Foundation
import WatchConnectivity

final class ImageSyncService: ObservableObject {
    static let shared = ImageSyncService()

    @Published private(set) var pendingTransfers: Int = 0
    @Published private(set) var isSyncing = false

    private let transport: ConnectivityTransport
    private var cancellables = Set<AnyCancellable>()
    private var syncedImageHashes: Set<String> = []
    private var pendingHashes: Set<String> = []
    private let syncedHashesKey = "syncedImageHashes"
    private var retryQueue: [(URL, [String: Any])] = []
    private var isProcessingRetry = false

    init(transport: ConnectivityTransport = .shared) {
        self.transport = transport
        loadSyncedHashes()
        setupObservers()
    }

    private func setupObservers() {
        transport.fileTransferFinished
            .receive(on: DispatchQueue.main)
            .sink { [weak self] transfer, error in
                self?.handleTransferFinished(transfer: transfer, error: error)
            }
            .store(in: &cancellables)
    }

    func syncImages(for checklistData: ChecklistData, galleryStorage: GalleryStorage) {
        guard WCSession.default.activationState == .activated else {
            #if DEBUG
                print("iOS ImageSync: WCSession not activated, activating...")
            #endif
            WCSession.default.activate()
            return
        }

        let usedImageNames = Set(
            checklistData.checklists.flatMap { checklist in
                checklist.items.map { $0.imageName }
            }.filter { !$0.isEmpty }
        )

        #if DEBUG
            print("iOS ImageSync: Starting sync")
            print("iOS ImageSync: Used image names: \(usedImageNames)")
            print("iOS ImageSync: Gallery items: \(galleryStorage.items.map { "\($0.label) -> \($0.imagePath)" })")
            print("iOS ImageSync: Already synced hashes: \(syncedImageHashes.count)")
        #endif

        guard !usedImageNames.isEmpty else {
            #if DEBUG
                print("iOS ImageSync: No images to sync")
            #endif
            return
        }

        isSyncing = true
        var transferCount = 0

        for item in galleryStorage.items {
            guard usedImageNames.contains(item.label) else {
                #if DEBUG
                    print("iOS ImageSync: Skipping \(item.label) - not in used images")
                #endif
                continue
            }

            guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                #if DEBUG
                    print("iOS ImageSync: Cannot get documents URL")
                #endif
                continue
            }

            let url = documentsURL.appendingPathComponent(item.imagePath)
            guard FileManager.default.fileExists(atPath: url.path) else {
                #if DEBUG
                    print("iOS ImageSync: File not found: \(url.path)")
                #endif
                continue
            }

            let imageHash = computeImageHash(for: url)
            let hashKey = "\(item.label):\(imageHash)"

            if syncedImageHashes.contains(hashKey) {
                #if DEBUG
                    print("iOS ImageSync: Already synced: \(item.label)")
                #endif
                continue
            }

            if pendingHashes.contains(hashKey) {
                #if DEBUG
                    print("iOS ImageSync: Already pending: \(item.label)")
                #endif
                continue
            }

            let metadata: [String: Any] = [
                SyncConstants.Keys.imageName: item.label,
                SyncConstants.Keys.imageHash: imageHash,
                SyncConstants.Keys.syncType: SyncMessageType.checklist.rawValue,
                SyncConstants.Keys.timestamp: Date().timeIntervalSince1970
            ]

            if transport.transferFile(url, metadata: metadata) != nil {
                transferCount += 1
                pendingHashes.insert(hashKey)
                #if DEBUG
                    print("iOS ImageSync: Queued file transfer: \(item.label)")
                #endif
            } else {
                #if DEBUG
                    print("iOS ImageSync: Failed to queue transfer: \(item.label)")
                #endif
            }
        }

        pendingTransfers = transferCount
        #if DEBUG
            print("iOS ImageSync: Total transfers queued: \(transferCount)")
        #endif

        if transferCount == 0 {
            isSyncing = false
        }
    }

    func forceSyncAllImages(for checklistData: ChecklistData, galleryStorage: GalleryStorage) {
        clearSyncedHashes()
        syncImages(for: checklistData, galleryStorage: galleryStorage)
    }

    func clearSyncedHashes() {
        syncedImageHashes.removeAll()
        pendingHashes.removeAll()
        saveSyncedHashes()
        #if DEBUG
            print("iOS ImageSync: Cleared all synced hashes")
        #endif
    }

    private func handleTransferFinished(transfer: WCSessionFileTransfer, error: Error?) {
        pendingTransfers = max(0, pendingTransfers - 1)

        guard let metadata = transfer.file.metadata,
              let imageName = metadata[SyncConstants.Keys.imageName] as? String,
              let imageHash = metadata[SyncConstants.Keys.imageHash] as? String else {
            #if DEBUG
                print("iOS ImageSync: Transfer finished but no metadata")
            #endif
            if pendingTransfers == 0 {
                isSyncing = false
            }
            return
        }

        let hashKey = "\(imageName):\(imageHash)"
        pendingHashes.remove(hashKey)

        if let error = error {
            #if DEBUG
                print("iOS ImageSync: Transfer FAILED for \(imageName): \(error.localizedDescription)")
                ErrorLogger.log(AppError.fileOperationFailed(operation: "file transfer", underlying: error))
            #endif

            retryQueue.append((transfer.file.fileURL, metadata))
            scheduleRetry()
        } else {
            syncedImageHashes.insert(hashKey)
            saveSyncedHashes()
            #if DEBUG
                print("iOS ImageSync: Transfer SUCCESS for \(imageName)")
            #endif
        }

        if pendingTransfers == 0 {
            isSyncing = false
            #if DEBUG
                print("iOS ImageSync: All transfers complete")
            #endif
        }
    }

    private func scheduleRetry() {
        guard !isProcessingRetry, !retryQueue.isEmpty else { return }
        isProcessingRetry = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.processRetryQueue()
        }
    }

    private func processRetryQueue() {
        guard !retryQueue.isEmpty else {
            isProcessingRetry = false
            return
        }

        let (fileURL, metadata) = retryQueue.removeFirst()

        guard FileManager.default.fileExists(atPath: fileURL.path),
              WCSession.default.activationState == .activated else {
            #if DEBUG
                print("iOS ImageSync: Retry skipped - file missing or session inactive")
            #endif
            isProcessingRetry = false
            scheduleRetry()
            return
        }

        if let imageName = metadata[SyncConstants.Keys.imageName] as? String,
           let imageHash = metadata[SyncConstants.Keys.imageHash] as? String {
            let hashKey = "\(imageName):\(imageHash)"
            pendingHashes.insert(hashKey)
        }

        if transport.transferFile(fileURL, metadata: metadata) != nil {
            pendingTransfers += 1
            isSyncing = true
            #if DEBUG
                if let imageName = metadata[SyncConstants.Keys.imageName] as? String {
                    print("iOS ImageSync: Retry queued for \(imageName)")
                }
            #endif
        }

        isProcessingRetry = false
        scheduleRetry()
    }

    private func computeImageHash(for url: URL) -> String {
        guard let data = try? Data(contentsOf: url) else { return UUID().uuidString }

        var hasher = Hasher()
        hasher.combine(data)
        return String(hasher.finalize())
    }

    private func loadSyncedHashes() {
        if let data = UserDefaults.standard.data(forKey: syncedHashesKey),
           let hashes = try? JSONDecoder().decode(Set<String>.self, from: data) {
            syncedImageHashes = hashes
        }
    }

    private func saveSyncedHashes() {
        if let data = try? JSONEncoder().encode(syncedImageHashes) {
            UserDefaults.standard.set(data, forKey: syncedHashesKey)
        }
    }
}

