import WatchConnectivity

extension WatchConnector {

  func updateChecklistData(_ data: ChecklistData) {
    self.checklistData = data
    saveChecklistData()
    forceSyncToWatch()
  }

  func forceSyncToWatch() {
    #if DEBUG
      print("🔄 iOS: forceSyncToWatch called")
    #endif

    guard WCSession.default.activationState == .activated else {
      #if DEBUG
        print("Session not activated, cannot sync")
      #endif
      WCSession.default.activate()
      return
    }

    syncChecklistToWatch()
  }

  func syncChecklistToWatch() {
    #if DEBUG
      print("🔄 iOS: syncChecklistToWatch called")
      print("   → Session state: \(WCSession.default.activationState.rawValue)")
      print("   → Is syncing: \(isSyncing)")
    #endif

    guard WCSession.default.activationState == .activated else {
      #if DEBUG
        print("Session not activated, skipping sync")
      #endif
      return
    }

    guard !isSyncing else {
      #if DEBUG
        print("Sync already in progress, skipping")
      #endif
      return
    }

    let currentHash = computeChecklistHash()
    if let lastHash = lastSyncedHash, lastHash == currentHash {
      #if DEBUG
        print("Checklist data unchanged (hash: \(currentHash)), skipping sync")
      #endif
      return
    }

    #if DEBUG
      print(
        "Checklist hash changed from \(lastSyncedHash?.description ?? "nil") to \(currentHash), syncing..."
      )
    #endif

    isSyncing = true

    do {
      let data = try JSONEncoder().encode(checklistData)
      var message: [String: Any] = [
        "action": "updateChecklist",
        "data": data.base64EncodedString(),
        "forceOverwrite": true,
        "timestamp": Date().timeIntervalSince1970,
      ]

      let galleryStorage = GalleryStorage.shared
      var imageData: [String: String] = [:]

      let usedImageNames = Set(
        checklistData.checklists.flatMap { checklist in
          checklist.items.map { $0.imageName }
        }.filter { !$0.isEmpty })

      for item in galleryStorage.items {
        guard usedImageNames.contains(item.label) else { continue }

        let documentsURL = FileManager.default.urls(
          for: .documentDirectory, in: .userDomainMask
        )
        .first
        guard let documentsURL = documentsURL else { continue }

        let url = documentsURL.appendingPathComponent(item.imagePath)

        guard FileManager.default.fileExists(atPath: url.path),
          let data = try? Data(contentsOf: url)
        else { continue }

        imageData[item.label] = data.base64EncodedString()
      }

      if !imageData.isEmpty {
        message["imageData"] = imageData

        do {
          let jsonData = try JSONSerialization.data(
            withJSONObject: message, options: [])
          let sizeInKB =
            Double(jsonData.count)
            / AppConstants.Network.bytesToKBDivisor

          #if DEBUG
            print(
              "Payload size: \(String(format: "%.1f", sizeInKB)) KB"
            )
          #endif

          if sizeInKB > AppConstants.Network.maxPayloadSizeKB {
            #if DEBUG
              print("Payload too large, sending without images")
            #endif
            message.removeValue(forKey: "imageData")
          }
        } catch {
          let appError = AppError.encodingFailed(
            type: "sync message", underlying: error)
          #if DEBUG
            ErrorLogger.log(appError)
          #endif
          message.removeValue(forKey: "imageData")
        }
      }

      #if DEBUG
        print(
          "Syncing checklist with \(checklistData.checklists.count) checklists"
        )
      #endif

      // Always use background sync like calendar does
      syncChecklistViaBackgroundTransfer(data: data, imageData: imageData, hashToSet: currentHash)
    } catch {
      let appError = AppError.encodingFailed(
        type: "checklist", underlying: error)
      #if DEBUG
        ErrorLogger.log(appError)
      #endif
      lastError = appError
      isSyncing = false
    }
  }

  private func computeChecklistHash() -> Int {
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

  private func syncChecklistViaBackgroundTransfer(
    data: Data, imageData: [String: String], hashToSet: Int?
  ) {
    do {
      let applicationContext: [String: Any] = [
        "checklistData": data.base64EncodedString(),
        "checklistImageData": imageData,
        "forceOverwrite": true,
        "timestamp": Date().timeIntervalSince1970,
      ]

      try WCSession.default.updateApplicationContext(applicationContext)

      DispatchQueue.main.async {
        self.isSyncing = false
        if let hash = hashToSet {
          self.lastSyncedHash = hash
        }
      }

      #if DEBUG
        print("✅ iOS: Checklist synced via background context")
        print("   → \(self.checklistData.checklists.count) checklists sent")
        print("   → Watch will receive even if app not running")
      #endif
    } catch {
      #if DEBUG
        print("❌ iOS: Failed to update application context: \(error.localizedDescription)")
      #endif

      DispatchQueue.main.async {
        self.isSyncing = false
        if let hash = hashToSet {
          self.lastSyncedHash = hash
        }
      }
    }
  }

  func saveChecklistData() {
    do {
      let data = try JSONEncoder().encode(checklistData)
      UserDefaults.standard.set(
        data, forKey: AppConstants.StorageKeys.checklistData)
    } catch {
      let appError = AppError.encodingFailed(
        type: "checklist data", underlying: error)
      #if DEBUG
        ErrorLogger.log(appError)
      #endif
      lastError = appError
    }
  }

  func loadChecklistData() {
    guard
      let data = UserDefaults.standard.data(
        forKey: AppConstants.StorageKeys.checklistData)
    else {
      checklistData = ChecklistData.default
      saveChecklistData()
      return
    }

    do {
      checklistData = try JSONDecoder().decode(
        ChecklistData.self, from: data)
    } catch {
      let appError = AppError.decodingFailed(
        type: "checklist data", underlying: error)
      #if DEBUG
        ErrorLogger.log(appError)
      #endif
      lastError = appError
      checklistData = ChecklistData.default
      saveChecklistData()
    }
  }

  func syncAuthToWatch() {
    guard WCSession.default.activationState == .activated else {
      #if DEBUG
        print("Session not activated, skipping auth sync")
      #endif
      return
    }

    guard WCSession.default.isReachable else { return }

    var message: [String: Any] = ["action": "updateAuth"]

    if let session = supabase.auth.currentSession {
      message["accessToken"] = session.accessToken
      message["refreshToken"] = session.refreshToken
      message["isLoggedIn"] = true
    } else {
      message["isLoggedIn"] = false
    }

    WCSession.default.sendMessage(message, replyHandler: nil) { error in
      #if DEBUG
        print(
          "Failed to sync auth to watch: \(error.localizedDescription)"
        )
      #endif
    }
  }

  func syncTelemetryToWatch() {
    guard WCSession.default.activationState == .activated else {
      #if DEBUG
        print("Session not activated, skipping telemetry sync")
      #endif
      return
    }

    let userInfo: [String: Any] = [
      "action": "updateTelemetry",
      "hasConsent": TelemetryManager.shared.hasConsent,
    ]

    if WCSession.default.isReachable {
      WCSession.default.sendMessage(userInfo, replyHandler: nil) {
        error in
        #if DEBUG
          print(
            "Failed to sync telemetry to watch: \(error.localizedDescription)"
          )
        #endif
        self.fallbackTelemetrySync(userInfo)
      }
    } else {
      fallbackTelemetrySync(userInfo)
    }
  }

  private func fallbackTelemetrySync(_ userInfo: [String: Any]) {
    do {
      try WCSession.default.updateApplicationContext(userInfo)
      #if DEBUG
        print("Telemetry synced via application context")
      #endif
    } catch {
      #if DEBUG
        print("Failed to update application context: \(error.localizedDescription)")
      #endif
      WCSession.default.transferUserInfo(userInfo)
      #if DEBUG
        print("Queued telemetry sync for background transfer")
      #endif
    }
  }
}
