import WatchConnectivity

extension WatchConnector {

  func session(
    _ session: WCSession,
    didReceiveMessage message: [String: Any],
    replyHandler: @escaping ([String: Any]) -> Void
  ) {
    handleIncomingMessage(message)
    replyHandler(["status": "success"])
  }

  func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    handleIncomingMessage(message)
  }

  func session(
    _ session: WCSession,
    didReceiveApplicationContext applicationContext: [String: Any]
  ) {
    handleIncomingMessage(applicationContext)
  }

  private func handleIncomingMessage(_ message: [String: Any]) {
    #if DEBUG
      print("📱 iOS: Received message from Watch with keys: \(message.keys)")
    #endif

    DispatchQueue.main.async {
      if let action = message["action"] as? String {
        #if DEBUG
          print("📱 iOS: Processing action: \(action)")
        #endif

        switch action {
        case "updateWatchUUID":
          if let watchUUID = message["watchUUID"] as? String {
            WatchConfig.shared.setConnectedWatchUUID(watchUUID)
            #if DEBUG
              print("📱 iOS: Received Watch UUID: \(String(watchUUID.prefix(8)))")
            #endif
          } else {
            #if DEBUG
              print("📱 iOS: updateWatchUUID action but no watchUUID in message")
            #endif
          }
        case "syncLevelFromWatch":
          if let dataString = message["data"] as? String,
            let data = Data(base64Encoded: dataString),
            let levelData = try? JSONDecoder().decode(LevelData.self, from: data)
          {
            var existingData = self.loadLevelData()
            existingData.currentLevel = levelData.currentLevel
            existingData.currentXP = levelData.currentXP
            existingData.totalXP = levelData.totalXP
            existingData.lastUpdated = levelData.lastUpdated
            self.saveLevelData(existingData)
            #if DEBUG
              print("📱 iOS: Updated level from Watch: Level \(levelData.currentLevel)")
            #endif
          }
        default:
          #if DEBUG
            print("📱 iOS: Unknown action: \(action)")
          #endif
        }
      } else {
        #if DEBUG
          print("📱 iOS: Message has no action key")
        #endif
      }
    }
  }
}
