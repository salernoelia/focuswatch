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
      guard let progress = LevelService.shared.currentProgress else { return }

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

        WCSession.default.sendMessage(message, replyHandler: nil) { error in
          #if DEBUG
            ErrorLogger.log(AppError.watchMessageFailed(underlying: error))
          #endif
        }
      } catch {
        #if DEBUG
          ErrorLogger.log(AppError.encodingFailed(type: "level data", underlying: error))
        #endif
      }
    }
  }
}
