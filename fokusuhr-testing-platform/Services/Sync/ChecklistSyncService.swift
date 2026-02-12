import Combine
import Foundation
import WatchConnectivity

final class ChecklistSyncService: ObservableObject {
    static let shared = ChecklistSyncService()

    @Published var checklistData = ChecklistData.default
    @Published var lastError: AppError?
    @Published private(set) var isSyncing = false
    @Published private(set) var syncProgress: Double = 0

    private let transport: ConnectivityTransport
    private let imageSyncService: ImageSyncService
    private var lastSyncedHash: Int?
    private let syncQueue = DispatchQueue(label: "com.fokusuhr.checklist.sync", qos: .userInitiated)
    private var debounceTimer: Timer?
    private var pendingSync = false
    private var retryCount = 0
    private var retryTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    init(transport: ConnectivityTransport = .shared, imageSyncService: ImageSyncService = .shared) {
        self.transport = transport
        self.imageSyncService = imageSyncService
        loadChecklistData()
        setupObservers()
    }

    private func setupObservers() {
        transport.messageReceived
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message, replyHandler in
                self?.handleMessage(message, replyHandler: replyHandler)
            }
            .store(in: &cancellables)

        transport.userInfoReceived
            .receive(on: DispatchQueue.main)
            .sink { [weak self] userInfo in
                self?.handleUserInfo(userInfo)
            }
            .store(in: &cancellables)

        imageSyncService.$syncProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.syncProgress = progress
            }
            .store(in: &cancellables)
    }

    private func handleMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)?) {
        guard let action = message[SyncConstants.Keys.action] as? String else {
            return
        }

        switch action {
        case SyncConstants.Actions.forceSync:
            #if DEBUG
                print("iOS ChecklistSync: Received forceSync request from Watch")
            #endif
            forceSyncWithImages()
            replyHandler?([SyncConstants.Keys.status: SyncConstants.Status.success])

        default:
            break
        }
    }

    private func handleUserInfo(_ userInfo: [String: Any]) {
        guard let action = userInfo[SyncConstants.Keys.action] as? String else {
            return
        }

        if action == SyncConstants.Actions.forceSync {
            #if DEBUG
                print("iOS ChecklistSync: Received forceSync via userInfo")
            #endif
            forceSyncWithImages()
        }
    }

    func updateChecklistData(_ data: ChecklistData) {
        self.checklistData = data
        saveChecklistData()
        debouncedSync()
    }

    func forceSync() {
        debounceTimer?.invalidate()
        retryCount = 0
        lastSyncedHash = nil
        
        syncQueue.async { [weak self] in
            self?.performSyncIfPossible()
        }
    }

    func forceSyncWithImages() {
        debounceTimer?.invalidate()
        retryCount = 0
        lastSyncedHash = nil
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isSyncing = true
            self.imageSyncService.forceSyncAllImages(
                for: self.checklistData,
                galleryStorage: GalleryStorage.shared
            )
        }
        
        syncQueue.async { [weak self] in
            self?.performSyncIfPossible()
        }
    }

    private func debouncedSync() {
        DispatchQueue.main.async { [weak self] in
            self?.debounceTimer?.invalidate()
            self?.pendingSync = true
            self?.debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                self?.syncQueue.async {
                    self?.performSyncIfPossible()
                }
            }
        }
    }

    private func performSyncIfPossible() {
        guard WCSession.default.activationState == .activated else {
            #if DEBUG
                print("iOS ChecklistSync: Session not activated, scheduling pending sync")
            #endif
            schedulePendingSync()
            return
        }

        guard !isSyncing || pendingSync else {
            #if DEBUG
                print("iOS ChecklistSync: Already syncing or no pending sync")
            #endif
            return
        }

        let currentHash = computeHash()
        if let lastHash = lastSyncedHash, lastHash == currentHash {
            #if DEBUG
                print("iOS ChecklistSync: Data unchanged (hash: \(currentHash)), skipping sync")
            #endif
            DispatchQueue.main.async { [weak self] in
                self?.pendingSync = false
            }
            return
        }

        #if DEBUG
            print("iOS ChecklistSync: Starting sync (hash: \(lastSyncedHash ?? 0) -> \(currentHash))")
        #endif

        DispatchQueue.main.async { [weak self] in
            self?.isSyncing = true
        }
        performSync(hashToSet: currentHash)
    }

    private func performSync(hashToSet: Int) {
        do {
            let data = try JSONEncoder().encode(checklistData)
            let syncId = UUID().uuidString
            let imageData = collectImageDataForContext()

            #if DEBUG
                print("iOS ChecklistSync: Preparing sync payload")
                print("iOS ChecklistSync: Checklists to sync: \(checklistData.checklists.count)")
                for (index, checklist) in checklistData.checklists.enumerated() {
                    print("iOS ChecklistSync:   [\(index)] \(checklist.name) - \(checklist.items.count) items")
                }
                print("iOS ChecklistSync: Encoded data size: \(data.count) bytes")
            #endif

            let requiredImages = Set(
                checklistData.checklists.flatMap { checklist in
                    checklist.items.compactMap { item in
                        item.imageName.isEmpty ? nil : item.imageName
                    }
                }
            )

            var context: [String: Any] = [
                SyncConstants.Keys.checklistData: data,
                SyncConstants.Keys.forceOverwrite: true,
                SyncConstants.Keys.timestamp: Date().timeIntervalSince1970,
                SyncConstants.Keys.syncId: syncId,
                SyncConstants.Keys.requiredImages: Array(requiredImages)
            ]

            if !imageData.isEmpty {
                context[SyncConstants.Keys.checklistImageData] = imageData
                #if DEBUG
                    print("iOS ChecklistSync: Including \(imageData.count) images in applicationContext")
                #endif
            } else {
                #if DEBUG
                    print("iOS ChecklistSync: No images in applicationContext, relying on file transfers")
                #endif
            }

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                #if DEBUG
                    print("iOS ChecklistSync: Starting ImageSyncService for \(requiredImages.count) images")
                #endif
                self.imageSyncService.syncImages(
                    for: self.checklistData,
                    galleryStorage: GalleryStorage.shared,
                    syncId: syncId
                )
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else { return }
                do {
                    try self.transport.updateApplicationContext(context)
                    
                    DispatchQueue.main.async {
                        self.lastSyncedHash = hashToSet
                        self.pendingSync = false
                        self.retryCount = 0
                        self.retryTimer?.invalidate()
                    }

                    #if DEBUG
                        print("iOS ChecklistSync: Synced - \(self.checklistData.checklists.count) checklists, syncId: \(syncId)")
                    #endif
                } catch {
                    self.handleSyncFailure(error: error, hashToSet: hashToSet)
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
                if self?.imageSyncService.isSyncing == false {
                    self?.isSyncing = false
                }
            }
        } catch {
            handleSyncFailure(error: error, hashToSet: hashToSet)
        }
    }

    private func handleSyncFailure(error: Error, hashToSet: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isSyncing = false
            self.lastError = AppError.encodingFailed(type: "checklist", underlying: error)

            if self.retryCount < SyncConstants.Timing.maxRetries {
                self.retryCount += 1
                let delay = min(pow(2.0, Double(self.retryCount)), 8.0)

                #if DEBUG
                    ErrorLogger.log("Sync failed, retrying in \(delay)s (attempt \(self.retryCount)/\(SyncConstants.Timing.maxRetries))")
                #endif

                self.retryTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                    self?.syncQueue.async {
                        self?.performSyncIfPossible()
                    }
                }
            } else {
                #if DEBUG
                    ErrorLogger.log(AppError.encodingFailed(type: "checklist", underlying: error))
                    ErrorLogger.log("Max retries reached, giving up")
                #endif
                self.retryCount = 0
            }
        }
    }

    private func schedulePendingSync() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard !self.pendingSync else { return }

            self.pendingSync = true

            #if DEBUG
                ErrorLogger.log("Watch not reachable, will retry when available")
            #endif

            self.retryTimer = Timer.scheduledTimer(withTimeInterval: SyncConstants.Timing.retryDelay, repeats: false) { [weak self] _ in
                self?.syncQueue.async {
                    self?.performSyncIfPossible()
                }
            }
        }
    }

    private func collectImageDataForContext() -> [String: String] {
        var imageData: [String: String] = [:]

        let galleryStorage = GalleryStorage.shared
        let usedImageNames = Set(
            checklistData.checklists.flatMap { checklist in
                checklist.items.map { $0.imageName }
            }.filter { !$0.isEmpty }
        )

        #if DEBUG
            print("iOS ChecklistSync: Used image names in checklists: \(usedImageNames.sorted())")
            print("iOS ChecklistSync: Gallery items: \(galleryStorage.items.map { $0.label }.sorted())")
        #endif

        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            #if DEBUG
                print("iOS ChecklistSync: Cannot get documents URL")
            #endif
            return [:]
        }

        var totalSize = 0
        for item in galleryStorage.items {
            guard usedImageNames.contains(item.label) else { continue }

            let url = documentsURL.appendingPathComponent(item.imagePath)
            
            guard FileManager.default.fileExists(atPath: url.path) else {
                #if DEBUG
                    print("iOS ChecklistSync: Image file not found: \(item.label) at \(url.path)")
                #endif
                continue
            }
            
            guard let fileData = try? Data(contentsOf: url) else {
                #if DEBUG
                    print("iOS ChecklistSync: Failed to read image data: \(item.label)")
                #endif
                continue
            }

            let base64String = fileData.base64EncodedString()
            let estimatedSize = base64String.count
            
            if totalSize + estimatedSize > Int(AppConstants.Network.maxPayloadSizeKB * AppConstants.Network.bytesToKBDivisor) {
                #if DEBUG
                    print("iOS ChecklistSync: Image \(item.label) would exceed payload limit, stopping context collection")
                    print("iOS ChecklistSync: Current size: \(totalSize / 1024) KB, Image size: \(estimatedSize / 1024) KB")
                #endif
                break
            }
            
            imageData[item.label] = base64String
            totalSize += estimatedSize
            #if DEBUG
                print("iOS ChecklistSync: Added image to context: \(item.label) (\(fileData.count) bytes)")
            #endif
        }

        if !imageData.isEmpty {
            let sizeInKB = Double(totalSize) / AppConstants.Network.bytesToKBDivisor
            #if DEBUG
                print("iOS ChecklistSync: Total image payload size: \(String(format: "%.2f", sizeInKB)) KB (max: \(AppConstants.Network.maxPayloadSizeKB) KB)")
                print("iOS ChecklistSync: Including \(imageData.count)/\(usedImageNames.count) images in applicationContext")
            #endif
        } else {
            #if DEBUG
                print("iOS ChecklistSync: No images collected for context, file transfer will handle all images")
            #endif
        }

        return imageData
    }

    private func computeHash() -> Int {
        var hasher = Hasher()
        hasher.combine(checklistData.checklists.count)
        for checklist in checklistData.checklists {
            hasher.combine(checklist.id)
            hasher.combine(checklist.name)
            hasher.combine(checklist.items.count)
            hasher.combine(checklist.xpReward)
            hasher.combine(checklist.resetConfiguration.interval.rawValue)
            hasher.combine(checklist.resetConfiguration.hour)
            hasher.combine(checklist.resetConfiguration.minute)
            hasher.combine(checklist.resetConfiguration.weekday)
            hasher.combine(checklist.swipeMapping.rawValue)
            for item in checklist.items {
                hasher.combine(item.id)
                hasher.combine(item.title)
                hasher.combine(item.imageName)
            }
        }
        return hasher.finalize()
    }

    func saveChecklistData() {
        do {
            let data = try JSONEncoder().encode(checklistData)
            UserDefaults.standard.set(data, forKey: AppConstants.StorageKeys.checklistData)
        } catch {
            #if DEBUG
                ErrorLogger.log(AppError.encodingFailed(type: "checklist data", underlying: error))
            #endif
            lastError = AppError.encodingFailed(type: "checklist data", underlying: error)
        }
    }

    func loadChecklistData() {
        guard let data = UserDefaults.standard.data(forKey: AppConstants.StorageKeys.checklistData) else {
            checklistData = ChecklistData.default
            saveChecklistData()
            return
        }

        do {
            checklistData = try JSONDecoder().decode(ChecklistData.self, from: data)
        } catch {
            #if DEBUG
                ErrorLogger.log(AppError.decodingFailed(type: "checklist data", underlying: error))
            #endif
            lastError = AppError.decodingFailed(type: "checklist data", underlying: error)
            checklistData = ChecklistData.default
            saveChecklistData()
        }
    }
}
