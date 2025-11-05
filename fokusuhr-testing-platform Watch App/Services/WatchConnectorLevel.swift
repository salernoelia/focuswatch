import Foundation
import WatchConnectivity

extension WatchConnector {
  func handleLevelUpdate(data: Data) {
    do {
      let levelData = try JSONDecoder().decode(LevelData.self, from: data)

      #if DEBUG
        ErrorLogger.log(
          "📊 Received level update from iOS: Level \(levelData.currentLevel), \(levelData.milestones.count) milestones"
        )
      #endif

      saveLevelMilestones(levelData.milestones)

      #if DEBUG
        ErrorLogger.log("📢 Watch: Posting LevelMilestonesUpdated notification")
      #endif

      NotificationCenter.default.post(
        name: NSNotification.Name("LevelMilestonesUpdated"), object: nil)

    } catch {
      #if DEBUG
        ErrorLogger.log(AppError.decodingFailed(type: "level data", underlying: error))
      #endif
    }
  }

  func saveLevelMilestones(_ milestones: [LevelMilestone]) {
    do {
      let data = try JSONEncoder().encode(milestones)
      UserDefaults.standard.set(data, forKey: "levelMilestones")
      #if DEBUG
        ErrorLogger.log("💾 Watch: Saved \(milestones.count) milestones to UserDefaults")
      #endif
    } catch {
      #if DEBUG
        ErrorLogger.log(AppError.encodingFailed(type: "level milestones", underlying: error))
      #endif
    }
  }

  func loadLevelMilestones() -> [LevelMilestone] {
    guard let data = UserDefaults.standard.data(forKey: "levelMilestones") else {
      return []
    }

    do {
      return try JSONDecoder().decode([LevelMilestone].self, from: data)
    } catch {
      #if DEBUG
        ErrorLogger.log(AppError.decodingFailed(type: "level milestones", underlying: error))
      #endif
      return []
    }
  }

  func syncLevelToiOS() {
    Task { @MainActor in
      guard let progress = LevelService.shared.currentProgress else {
        #if DEBUG
          ErrorLogger.log("⚠️ Watch: No progress to sync")
        #endif
        return
      }

      let levelData = LevelData(
        currentLevel: progress.currentLevel,
        currentXP: progress.currentXP,
        totalXP: progress.totalXP,
        milestones: loadLevelMilestones(),
        lastUpdated: progress.lastUpdated
      )

      do {
        let data = try JSONEncoder().encode(levelData)
        let message: [String: Any] = [
          "action": "syncLevelFromWatch",
          "data": data.base64EncodedString(),
          "timestamp": Date().timeIntervalSince1970,
        ]

        #if DEBUG
          ErrorLogger.log(
            "⌚ Watch: Syncing level to iOS: Level \(levelData.currentLevel), XP: \(levelData.currentXP)"
          )
        #endif

        guard WCSession.default.activationState == .activated else {
          #if DEBUG
            ErrorLogger.log("⚠️ Watch: Session not activated")
          #endif
          return
        }

        // Triple-redundant sync approach

        // 1. Application context (persists)
        do {
          try WCSession.default.updateApplicationContext(message)
          #if DEBUG
            ErrorLogger.log("✅ Watch: Level synced via application context")
          #endif
        } catch {
          #if DEBUG
            ErrorLogger.log("⚠️ Watch: Application context failed: \(error.localizedDescription)")
          #endif
        }

        // 2. Immediate message if reachable
        if WCSession.default.isReachable {
          WCSession.default.sendMessage(
            message,
            replyHandler: { response in
              #if DEBUG
                ErrorLogger.log("✅ Watch: Level sync immediate message delivered")
              #endif
            }
          ) { error in
            #if DEBUG
              ErrorLogger.log("⚠️ Watch: Immediate message failed: \(error.localizedDescription)")
            #endif
          }
        }

        // 3. Background transfer
        WCSession.default.transferUserInfo(message)
        #if DEBUG
          ErrorLogger.log("✅ Watch: Level queued for background transfer")
        #endif

      } catch {
        #if DEBUG
          ErrorLogger.log(AppError.encodingFailed(type: "level data", underlying: error))
        #endif
      }
    }
  }

  func requestLevelDataFromiOS() {
    guard WCSession.default.activationState == .activated else {
      #if DEBUG
        ErrorLogger.log("⚠️ Watch: Session not activated, cannot request level data")
      #endif
      return
    }

    let message: [String: Any] = [
      "action": "requestLevelData",
      "timestamp": Date().timeIntervalSince1970,
    ]

    #if DEBUG
      ErrorLogger.log("⌚ Watch: Requesting level data from iOS")
    #endif

    if WCSession.default.isReachable {
      WCSession.default.sendMessage(
        message,
        replyHandler: { response in
          #if DEBUG
            ErrorLogger.log("✅ Watch: Level data request sent")
          #endif
        }
      ) { error in
        #if DEBUG
          ErrorLogger.log("⚠️ Watch: Level data request failed: \(error.localizedDescription)")
        #endif
      }
    }
  }
}
