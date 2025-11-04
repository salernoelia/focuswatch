import WatchConnectivity

extension WatchConnector {

  func syncLevelToWatch() {
    guard WCSession.default.activationState == .activated else {
      #if DEBUG
        print("Session not activated, skipping level sync")
      #endif
      return
    }

    guard !isSyncing else {
      #if DEBUG
        print("Sync already in progress, skipping level sync")
      #endif
      return
    }

    do {
      let levelData = loadLevelData()
      let data = try JSONEncoder().encode(levelData)

      let message: [String: Any] = [
        "action": "updateLevel",
        "data": data.base64EncodedString(),
        "timestamp": Date().timeIntervalSince1970,
      ]

      #if DEBUG
        print(
          "Syncing level data to watch: Level \(levelData.currentLevel), \(levelData.milestones.count) milestones"
        )
      #endif

      if WCSession.default.isReachable {
        WCSession.default.sendMessage(
          message,
          replyHandler: { response in
            #if DEBUG
              print("Level sync successful: \(response)")
            #endif
          }
        ) { error in
          #if DEBUG
            print("Level sync failed, using background transfer: \(error.localizedDescription)")
          #endif
          self.fallbackLevelSync(message)
        }
      } else {
        fallbackLevelSync(message)
      }
    } catch {
      let appError = AppError.encodingFailed(type: "level data", underlying: error)
      #if DEBUG
        ErrorLogger.log(appError)
      #endif
      lastError = appError
    }
  }

  private func fallbackLevelSync(_ message: [String: Any]) {
    do {
      try WCSession.default.updateApplicationContext(message)
      #if DEBUG
        print("✅ Level synced via application context")
      #endif
    } catch {
      #if DEBUG
        print("Failed to update application context: \(error.localizedDescription)")
      #endif
      WCSession.default.transferUserInfo(message)
      #if DEBUG
        print("✅ Level queued for background transfer")
      #endif
    }
  }

  func saveLevelData(_ levelData: LevelData) {
    do {
      let data = try JSONEncoder().encode(levelData)
      UserDefaults.standard.set(data, forKey: "levelData")
      syncLevelToWatch()
    } catch {
      let appError = AppError.encodingFailed(type: "level data", underlying: error)
      #if DEBUG
        ErrorLogger.log(appError)
      #endif
      lastError = appError
    }
  }

  func loadLevelData() -> LevelData {
    guard let data = UserDefaults.standard.data(forKey: "levelData") else {
      return LevelData.default
    }

    do {
      return try JSONDecoder().decode(LevelData.self, from: data)
    } catch {
      let appError = AppError.decodingFailed(type: "level data", underlying: error)
      #if DEBUG
        ErrorLogger.log(appError)
      #endif
      return LevelData.default
    }
  }
}
