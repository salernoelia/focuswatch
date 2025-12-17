import Foundation
import WatchConnectivity

final class ChecklistSyncService: ObservableObject {
  static let shared = ChecklistSyncService()

  @Published var checklistData = ChecklistData.default
  @Published var lastError: AppError?

  private let transport: ConnectivityTransport
  private let imageSyncService: ImageSyncService
  private var lastSyncedHash: Int?
  private var isSyncing = false
  private let syncQueue = DispatchQueue(label: "com.fokusuhr.checklist.sync", qos: .userInitiated)
  private var debounceTimer: Timer?
  private var pendingSync = false
  private var retryCount = 0
  private let maxRetries = 3
  private var retryTimer: Timer?

  init(transport: ConnectivityTransport = .shared, imageSyncService: ImageSyncService = .shared) {
    self.transport = transport
    self.imageSyncService = imageSyncService
    loadChecklistData()
  }

  func updateChecklistData(_ data: ChecklistData) {
    self.checklistData = data
    saveChecklistData()
    debouncedSync()
  }

  func forceSync() {
    debounceTimer?.invalidate()
    retryCount = 0
    syncQueue.async { [weak self] in
      self?.performSyncIfPossible()
    }
  }

  func forceSyncWithImages() {
    debounceTimer?.invalidate()
    retryCount = 0
    syncQueue.async { [weak self] in
      guard let self = self else { return }
      DispatchQueue.main.async {
        self.lastSyncedHash = nil
        self.imageSyncService.forceSyncAllImages(
          for: self.checklistData, galleryStorage: GalleryStorage.shared)
      }
      self.performSyncIfPossible()
    }
  }

  private func debouncedSync() {
    DispatchQueue.main.async { [weak self] in
      self?.debounceTimer?.invalidate()
      self?.pendingSync = true
      self?.debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) {
        [weak self] _ in
        self?.syncQueue.async {
          self?.performSyncIfPossible()
        }
      }
    }
  }

  private func performSyncIfPossible() {
    guard WCSession.default.activationState == .activated else {
      schedulePendingSync()
      return
    }

    guard WCSession.default.isReachable else {
      schedulePendingSync()
      return
    }

    guard !isSyncing else { return }

    let currentHash = computeHash()
    if let lastHash = lastSyncedHash, lastHash == currentHash {
      DispatchQueue.main.async { [weak self] in
        self?.pendingSync = false
      }
      return
    }

    isSyncing = true
    performSync(hashToSet: currentHash)
  }

  private func performSync(hashToSet: Int) {
    do {
      let data = try JSONEncoder().encode(checklistData)
      let imageData = collectImageDataForContext()

      var context: [String: Any] = [
        SyncConstants.Keys.checklistData: data,
        SyncConstants.Keys.forceOverwrite: true,
        SyncConstants.Keys.timestamp: Date().timeIntervalSince1970,
      ]

      if !imageData.isEmpty {
        context[SyncConstants.Keys.checklistImageData] = imageData
        #if DEBUG
          print("iOS: Including \(imageData.count) images in applicationContext")
        #endif
      }

      try transport.updateApplicationContext(context)

      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        self.imageSyncService.syncImages(
          for: self.checklistData, galleryStorage: GalleryStorage.shared)
        self.isSyncing = false
        self.lastSyncedHash = hashToSet
        self.pendingSync = false
        self.retryCount = 0
        self.retryTimer?.invalidate()
      }

      #if DEBUG
        print("iOS: Checklist synced - \(self.checklistData.checklists.count) checklists")
      #endif
    } catch {
      handleSyncFailure(error: error, hashToSet: hashToSet)
    }
  }

  private func handleSyncFailure(error: Error, hashToSet: Int) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.isSyncing = false
      self.lastError = AppError.encodingFailed(type: "checklist", underlying: error)

      if self.retryCount < self.maxRetries {
        self.retryCount += 1
        let delay = min(pow(2.0, Double(self.retryCount)), 8.0)

        #if DEBUG
          ErrorLogger.log(
            "Sync failed, retrying in \(delay)s (attempt \(self.retryCount)/\(self.maxRetries))")
        #endif

        self.retryTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) {
          [weak self] _ in
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

      self.retryTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) {
        [weak self] _ in
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
      print("iOS: Used image names in checklists: \(usedImageNames)")
      print("iOS: Gallery items: \(galleryStorage.items.map { $0.label })")
    #endif

    for item in galleryStorage.items {
      guard usedImageNames.contains(item.label) else { continue }

      guard
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
          .first
      else { continue }

      let url = documentsURL.appendingPathComponent(item.imagePath)
      guard FileManager.default.fileExists(atPath: url.path),
        let fileData = try? Data(contentsOf: url)
      else { continue }

      imageData[item.label] = fileData.base64EncodedString()
      #if DEBUG
        print("iOS: Added image to context: \(item.label) (\(fileData.count) bytes)")
      #endif
    }

    if !imageData.isEmpty {
      do {
        let checkPayloadSize = try JSONSerialization.data(withJSONObject: imageData, options: [])
        let sizeInKB = Double(checkPayloadSize.count) / AppConstants.Network.bytesToKBDivisor
        #if DEBUG
          print(
            "iOS: Total image payload size: \(sizeInKB) KB (max: \(AppConstants.Network.maxPayloadSizeKB) KB)"
          )
        #endif
        if sizeInKB > AppConstants.Network.maxPayloadSizeKB {
          #if DEBUG
            print("iOS: Image payload too large, will use file transfer only")
          #endif
          return [:]
        }
      } catch {
        return [:]
      }
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
    guard let data = UserDefaults.standard.data(forKey: AppConstants.StorageKeys.checklistData)
    else {
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
