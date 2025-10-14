import WatchConnectivity

extension WatchConnector {

  func updateChecklistData(_ data: ChecklistData) {
    self.checklistData = data
    saveChecklistData()
    forceSyncToWatch()
  }

  func forceSyncToWatch() {
    guard WCSession.default.isReachable else {
      lastError = .watchNotReachable
      #if DEBUG
        print("Watch not reachable for force sync")
      #endif
      return
    }
    syncChecklistToWatch()
  }

  func syncChecklistToWatch() {
    guard WCSession.default.isReachable else {
      lastError = .watchNotReachable
      #if DEBUG
        print("Watch not reachable for sync")
      #endif
      return
    }

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
          "Sending force sync with \(checklistData.checklists.count) checklists"
        )
      #endif

      WCSession.default.sendMessage(
        message,
        replyHandler: { response in
          #if DEBUG
            print("Checklist force sync successful: \(response)")
          #endif
        }
      ) { error in
        let appError = AppError.watchMessageFailed(underlying: error)
        #if DEBUG
          ErrorLogger.log(appError)
        #endif
        self.lastError = appError
      }
    } catch {
      let appError = AppError.encodingFailed(
        type: "checklist", underlying: error)
      #if DEBUG
        ErrorLogger.log(appError)
      #endif
      lastError = appError
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
