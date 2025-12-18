import Combine
import Foundation
import WatchConnectivity

final class ImageSyncService: ObservableObject {
    static let shared = ImageSyncService()

    @Published private(set) var pendingTransfers: Int = 0
    @Published private(set) var isSyncing = false
    @Published private(set) var syncProgress: Double = 0

    private let transport: ConnectivityTransport
    private let stateManager = SyncStateManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var syncedImageHashes: Set<String> = []
    private var pendingHashes: Set<String> = []
    private let syncedHashesKey = "syncedImageHashes"
    private var retryQueue: [(URL, [String: Any])] = []
    private var isProcessingRetry = false
    private var verificationTimer: Timer?
    private var currentSyncId: String?

    init(transport: ConnectivityTransport = .shared) {
        self.transport = transport
        loadSyncedHashes()
        setupObservers()
        startVerificationTimer()
    }

    private func setupObservers() {
        transport.fileTransferFinished
            .receive(on: DispatchQueue.main)
            .sink { [weak self] transfer, error in
                self?.handleTransferFinished(transfer: transfer, error: error)
            }
            .store(in: &cancellables)

        transport.messageReceived
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message, replyHandler in
                self?.handleMessage(message, replyHandler: replyHandler)
            }
            .store(in: &cancellables)
    }

    private func startVerificationTimer() {
        verificationTimer?.invalidate()
        verificationTimer = Timer.scheduledTimer(
            withTimeInterval: SyncConstants.Timing.verificationInterval,
            repeats: true
        ) { [weak self] _ in
            self?.checkSyncState()
        }
    }

    private func checkSyncState() {
        guard let state = stateManager.getCurrentState(), !state.isComplete else { return }

        if state.needsRetry {
            #if DEBUG
                print("iOS ImageSync: Sync state needs retry - missing images: \(state.missingImages)")
            #endif
            stateManager.updateState { $0.incrementRetry() }
            retryMissingImages(state.missingImages)
        }
    }

    func syncImages(for checklistData: ChecklistData, galleryStorage: GalleryStorage, syncId: String? = nil) {
        let id = syncId ?? UUID().uuidString
        currentSyncId = id

        if WCSession.default.activationState != .activated {
            #if DEBUG
                print("iOS ImageSync: WCSession not activated, activating...")
            #endif
            WCSession.default.activate()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.syncImages(for: checklistData, galleryStorage: galleryStorage, syncId: id)
            }
            return
        }

        let usedImageNames = Set(
            checklistData.checklists.flatMap { checklist in
                checklist.items.compactMap { item in
                    item.imageName.isEmpty ? nil : item.imageName
                }
            }
        )

        #if DEBUG
            print("iOS ImageSync: Starting sync for syncId: \(id)")
            print("iOS ImageSync: Required images: \(usedImageNames.sorted())")
            print("iOS ImageSync: Gallery items: \(galleryStorage.items.map { "\($0.label) -> \($0.imagePath)" })")
        #endif

        stateManager.startNewSync(id: id, requiredImages: usedImageNames)

        guard !usedImageNames.isEmpty else {
            #if DEBUG
                print("iOS ImageSync: No images required")
            #endif
            stateManager.updateState { state in
                state.markChecklistSynced()
            }
            stateManager.completeCurrentSync()
            return
        }

        isSyncing = true
        syncProgress = 0
        var transferCount = 0
        var successfullyQueued: [String] = []
        var failedImages: [String] = []

        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            #if DEBUG
                print("iOS ImageSync: Cannot get documents URL")
            #endif
            isSyncing = false
            return
        }

        for imageName in usedImageNames {
            guard let item = galleryStorage.items.first(where: { $0.label == imageName }) else {
                #if DEBUG
                    print("iOS ImageSync: Image '\(imageName)' not found in gallery storage")
                #endif
                stateManager.updateState { $0.markImageFailed(imageName) }
                failedImages.append(imageName)
                continue
            }

            let url = documentsURL.appendingPathComponent(item.imagePath)
            guard FileManager.default.fileExists(atPath: url.path) else {
                #if DEBUG
                    print("iOS ImageSync: File not found at path: \(url.path) for image: \(imageName)")
                #endif
                stateManager.updateState { $0.markImageFailed(imageName) }
                failedImages.append(imageName)
                continue
            }

            guard let fileData = try? Data(contentsOf: url) else {
                #if DEBUG
                    print("iOS ImageSync: Failed to read file data for: \(imageName)")
                #endif
                stateManager.updateState { $0.markImageFailed(imageName) }
                failedImages.append(imageName)
                continue
            }

            let imageHash = computeImageHash(for: url)
            let metadata: [String: Any] = [
                SyncConstants.Keys.imageName: imageName,
                SyncConstants.Keys.imageHash: imageHash,
                SyncConstants.Keys.syncType: SyncMessageType.checklist.rawValue,
                SyncConstants.Keys.syncId: id,
                SyncConstants.Keys.timestamp: Date().timeIntervalSince1970
            ]

            if transport.transferFile(url, metadata: metadata) != nil {
                transferCount += 1
                successfullyQueued.append(imageName)
                stateManager.updateState { $0.markImageTransferred(imageName) }
                #if DEBUG
                    print("iOS ImageSync: Queued transfer: \(imageName) (\(fileData.count) bytes)")
                #endif
            } else {
                #if DEBUG
                    print("iOS ImageSync: Failed to queue transfer: \(imageName)")
                #endif
                retryQueue.append((url, metadata))
                stateManager.updateState { $0.markImageFailed(imageName) }
                failedImages.append(imageName)
            }
        }

        pendingTransfers = transferCount
        #if DEBUG
            print("iOS ImageSync: Transfer summary - Queued: \(transferCount), Failed: \(failedImages.count)")
            if !failedImages.isEmpty {
                print("iOS ImageSync: Failed images: \(failedImages.sorted())")
            }
            if transferCount > 0 {
                print("iOS ImageSync: Outstanding file transfers: \(WCSession.default.outstandingFileTransfers.count)")
            }
        #endif

        if transferCount == 0 {
            isSyncing = false
            if usedImageNames.isEmpty || successfullyQueued.isEmpty {
                stateManager.completeCurrentSync()
            }
        }

        if !retryQueue.isEmpty {
            scheduleRetry()
        }
    }

    private func retryMissingImages(_ imageNames: Set<String>) {
        guard !imageNames.isEmpty else { return }

        let galleryStorage = GalleryStorage.shared
        guard
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        else { return }

        var retryCount = 0
        let syncId = currentSyncId ?? stateManager.getCurrentState()?.id ?? UUID().uuidString

        for imageName in imageNames {
            guard let item = galleryStorage.items.first(where: { $0.label == imageName }) else {
                continue
            }

            let url = documentsURL.appendingPathComponent(item.imagePath)
            guard FileManager.default.fileExists(atPath: url.path) else { continue }

            let imageHash = computeImageHash(for: url)
            let metadata: [String: Any] = [
                SyncConstants.Keys.imageName: imageName,
                SyncConstants.Keys.imageHash: imageHash,
                SyncConstants.Keys.syncType: SyncMessageType.checklist.rawValue,
                SyncConstants.Keys.syncId: syncId,
                SyncConstants.Keys.timestamp: Date().timeIntervalSince1970
            ]

            if transport.transferFile(url, metadata: metadata) != nil {
                retryCount += 1
                stateManager.updateState { $0.markImageTransferred(imageName) }
                #if DEBUG
                    print("iOS ImageSync: Retry queued for: \(imageName)")
                #endif
            }
        }

        if retryCount > 0 {
            pendingTransfers += retryCount
            isSyncing = true
        }
    }

    private func handleMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)?) {
        guard let action = message[SyncConstants.Keys.action] as? String else {
            replyHandler?([SyncConstants.Keys.status: SyncConstants.Status.noAction])
            return
        }

        switch action {
        case SyncConstants.Actions.acknowledgeImages:
            if let receivedImages = message[SyncConstants.Keys.receivedImages] as? [String] {
                handleImageAcknowledgment(receivedImages)
            }
            replyHandler?([SyncConstants.Keys.status: SyncConstants.Status.success])

        case SyncConstants.Actions.requestMissingImages:
            if let missingImages = message[SyncConstants.Keys.missingImages] as? [String] {
                #if DEBUG
                    print("iOS ImageSync: Watch requests missing images: \(missingImages)")
                #endif
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    self?.retryMissingImages(Set(missingImages))
                }
            }
            replyHandler?([SyncConstants.Keys.status: SyncConstants.Status.success])

        case SyncConstants.Actions.reportSyncStatus:
            if let status = message[SyncConstants.Keys.syncStatus] as? String {
                handleSyncStatusReport(status, message: message)
            }
            replyHandler?([SyncConstants.Keys.status: SyncConstants.Status.success])

        default:
            replyHandler?([SyncConstants.Keys.status: SyncConstants.Status.unknownAction])
        }
    }

    private func handleImageAcknowledgment(_ imageNames: [String]) {
        #if DEBUG
            print("iOS ImageSync: Received acknowledgment for \(imageNames.count) images: \(imageNames)")
        #endif

        stateManager.updateState { state in
            state.markImagesAcknowledged(imageNames)
        }

        updateSyncProgress()

        if let state = stateManager.getCurrentState(), state.allImagesAcknowledged {
            #if DEBUG
                print("iOS ImageSync: All images acknowledged - sync complete")
            #endif
            stateManager.completeCurrentSync()
            isSyncing = false
            syncProgress = 1.0
            NotificationCenter.default.post(
                name: NSNotification.Name("AllImagesAcknowledged"),
                object: state.id
            )
        }
    }

    private func handleSyncStatusReport(_ status: String, message: [String: Any]) {
        #if DEBUG
            print("iOS ImageSync: Watch reported sync status: \(status)")
        #endif

        if status == SyncConstants.Status.partial || status == SyncConstants.Status.failed {
            if let missingImages = message[SyncConstants.Keys.missingImages] as? [String], !missingImages.isEmpty {
                #if DEBUG
                    print("iOS ImageSync: Watch missing images: \(missingImages)")
                #endif
                DispatchQueue.main.asyncAfter(deadline: .now() + SyncConstants.Timing.retryDelay) { [weak self] in
                    self?.retryMissingImages(Set(missingImages))
                }
            }
        }
    }

    private func updateSyncProgress() {
        guard let state = stateManager.getCurrentState() else {
            syncProgress = 0
            return
        }

        let total = state.requiredImages.count
        if total == 0 {
            syncProgress = 1.0
            return
        }

        let acknowledged = state.acknowledgedImages.count
        syncProgress = Double(acknowledged) / Double(total)
    }

    func forceSyncAllImages(for checklistData: ChecklistData, galleryStorage: GalleryStorage) {
        clearSyncedHashes()
        stateManager.clearAll()
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

    func hasOutstandingTransfers() -> Bool {
        !WCSession.default.outstandingFileTransfers.isEmpty || pendingTransfers > 0
    }

    func cancelAllOutstandingTransfers() {
        for transfer in WCSession.default.outstandingFileTransfers {
            transfer.cancel()
        }
        pendingTransfers = 0
        pendingHashes.removeAll()
        retryQueue.removeAll()
        #if DEBUG
            print("iOS ImageSync: Cancelled all outstanding transfers")
        #endif
    }

    private func handleTransferFinished(transfer: WCSessionFileTransfer, error: Error?) {
        pendingTransfers = max(0, pendingTransfers - 1)

        guard let metadata = transfer.file.metadata,
              let imageName = metadata[SyncConstants.Keys.imageName] as? String,
              let imageHash = metadata[SyncConstants.Keys.imageHash] as? String
        else {
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

            stateManager.updateState { $0.markImageFailed(imageName) }
            retryQueue.append((transfer.file.fileURL, metadata))
            scheduleRetry()
        } else {
            syncedImageHashes.insert(hashKey)
            saveSyncedHashes()
            #if DEBUG
                print("iOS ImageSync: Transfer SUCCESS for \(imageName)")
            #endif
        }

        if pendingTransfers == 0 && retryQueue.isEmpty {
            #if DEBUG
                print("iOS ImageSync: All transfers complete")
            #endif
            if stateManager.getCurrentState()?.allImagesAcknowledged == true {
                isSyncing = false
            }
        }
    }

    private func scheduleRetry() {
        guard !isProcessingRetry, !retryQueue.isEmpty else { return }
        isProcessingRetry = true

        DispatchQueue.main.asyncAfter(deadline: .now() + SyncConstants.Timing.retryDelay) { [weak self] in
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
              WCSession.default.activationState == .activated
        else {
            #if DEBUG
                print("iOS ImageSync: Retry skipped - file missing or session inactive")
            #endif
            isProcessingRetry = false
            scheduleRetry()
            return
        }

        if let imageName = metadata[SyncConstants.Keys.imageName] as? String,
           let imageHash = metadata[SyncConstants.Keys.imageHash] as? String
        {
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
           let hashes = try? JSONDecoder().decode(Set<String>.self, from: data)
        {
            syncedImageHashes = hashes
        }
    }

    private func saveSyncedHashes() {
        if let data = try? JSONEncoder().encode(syncedImageHashes) {
            UserDefaults.standard.set(data, forKey: syncedHashesKey)
        }
    }
}
