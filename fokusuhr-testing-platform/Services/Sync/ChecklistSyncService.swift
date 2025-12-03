import Foundation
import WatchConnectivity

final class ChecklistSyncService: ObservableObject {
    static let shared = ChecklistSyncService()

    @Published var checklistData = ChecklistData.default
    @Published var lastError: AppError?

    private let transport: ConnectivityTransport
    private var lastSyncedHash: Int?
    var isSyncing = false

    init(transport: ConnectivityTransport = .shared) {
        self.transport = transport
        loadChecklistData()
    }

    func updateChecklistData(_ data: ChecklistData) {
        self.checklistData = data
        saveChecklistData()
        forceSync()
    }

    func forceSync() {
        guard WCSession.default.activationState == .activated else {
            WCSession.default.activate()
            return
        }
        sync()
    }

    func sync() {
        guard WCSession.default.activationState == .activated else { return }
        guard !isSyncing else { return }

        let currentHash = computeHash()
        if let lastHash = lastSyncedHash, lastHash == currentHash {
            return
        }

        isSyncing = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.performSync(hashToSet: currentHash)
        }
    }

    private func performSync(hashToSet: Int) {
        do {
            let data = try JSONEncoder().encode(checklistData)
            var imageData: [String: String] = [:]

            let galleryStorage = GalleryStorage.shared
            let usedImageNames = Set(
                checklistData.checklists.flatMap { checklist in
                    checklist.items.map { $0.imageName }
                }.filter { !$0.isEmpty }
            )

            for item in galleryStorage.items {
                guard usedImageNames.contains(item.label) else { continue }

                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                guard let documentsURL = documentsURL else { continue }

                let url = documentsURL.appendingPathComponent(item.imagePath)
                guard FileManager.default.fileExists(atPath: url.path),
                      let fileData = try? Data(contentsOf: url) else { continue }

                imageData[item.label] = fileData.base64EncodedString()
            }

            if !imageData.isEmpty {
                let checkPayloadSize = try JSONSerialization.data(withJSONObject: imageData, options: [])
                let sizeInKB = Double(checkPayloadSize.count) / AppConstants.Network.bytesToKBDivisor
                if sizeInKB > AppConstants.Network.maxPayloadSizeKB {
                    imageData = [:]
                }
            }

            let context: [String: Any] = [
                SyncConstants.Keys.checklistData: data,
                SyncConstants.Keys.checklistImageData: imageData,
                SyncConstants.Keys.forceOverwrite: true,
                SyncConstants.Keys.timestamp: Date().timeIntervalSince1970
            ]

            try transport.updateApplicationContext(context)

            DispatchQueue.main.async {
                self.isSyncing = false
                self.lastSyncedHash = hashToSet
            }

            #if DEBUG
                print("iOS: Checklist synced - \(self.checklistData.checklists.count) checklists")
            #endif
        } catch {
            DispatchQueue.main.async {
                self.isSyncing = false
                self.lastError = AppError.encodingFailed(type: "checklist", underlying: error)
            }
            #if DEBUG
                ErrorLogger.log(AppError.encodingFailed(type: "checklist", underlying: error))
            #endif
        }
    }

    private func computeHash() -> Int {
        var hasher = Hasher()
        hasher.combine(checklistData.checklists.count)
        for checklist in checklistData.checklists {
            hasher.combine(checklist.id)
            hasher.combine(checklist.name)
            hasher.combine(checklist.items.count)
            hasher.combine(checklist.xpReward)
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

