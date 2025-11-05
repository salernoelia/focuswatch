import WatchConnectivity

extension WatchConnector {

  func syncLevelToWatch() {
    guard WCSession.default.activationState == .activated else {
      #if DEBUG
        print("⚠️ iOS: Session not activated, will retry in 1 second")
      #endif
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
        self?.syncLevelToWatch()
      }
      return
    }

    guard !isSyncing else {
      #if DEBUG
        print("⚠️ iOS: Sync already in progress")
      #endif
      return
    }

    isSyncing = true

    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self = self else { return }

      do {
        let levelData = self.loadLevelData()
        let data = try JSONEncoder().encode(levelData)

        let message: [String: Any] = [
          "action": "updateLevel",
          "data": data.base64EncodedString(),
          "timestamp": Date().timeIntervalSince1970,
        ]

        #if DEBUG
          DispatchQueue.main.async {
            print(
              "📱 iOS: Syncing level to Watch: Level \(levelData.currentLevel), \(levelData.milestones.count) milestones"
            )
          }
        #endif

        // 1. Application Context (persists across restarts)
        do {
          try WCSession.default.updateApplicationContext(message)
          #if DEBUG
            DispatchQueue.main.async {
              print("✅ iOS: Level synced via application context")
            }
          #endif
        } catch {
          #if DEBUG
            DispatchQueue.main.async {
              print("⚠️ iOS: Application context failed: \(error.localizedDescription)")
            }
          #endif
        }

        // 2. Immediate message if reachable
        if WCSession.default.isReachable {
          WCSession.default.sendMessage(
            message,
            replyHandler: { response in
              #if DEBUG
                DispatchQueue.main.async {
                  print("✅ iOS: Level sync immediate message delivered")
                }
              #endif
            }
          ) { error in
            #if DEBUG
              DispatchQueue.main.async {
                print("⚠️ iOS: Immediate message failed: \(error.localizedDescription)")
              }
            #endif
          }
        }

        // 3. Background transfer as backup
        WCSession.default.transferUserInfo(message)
        #if DEBUG
          DispatchQueue.main.async {
            print("✅ iOS: Level queued for background transfer")
          }
        #endif

        DispatchQueue.main.async {
          self.isSyncing = false
        }
      } catch {
        DispatchQueue.main.async {
          self.isSyncing = false
          let appError = AppError.encodingFailed(type: "level data", underlying: error)
          #if DEBUG
            ErrorLogger.log(appError)
          #endif
          self.lastError = appError
        }
      }
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

      #if DEBUG
        print("💾 iOS: Saved level data to UserDefaults - triggering immediate sync")
      #endif
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
