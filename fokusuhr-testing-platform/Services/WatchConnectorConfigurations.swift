import WatchConnectivity

extension WatchConnector {

  func syncAppConfigurations(_ configurations: AppConfigurations) {
    guard WCSession.default.activationState == .activated else {
      #if DEBUG
        print("📱 iOS: Session not activated, skipping configuration sync")
      #endif
      return
    }

    do {
      let data = try JSONEncoder().encode(configurations)

      let applicationContext: [String: Any] = [
        "appConfigurations": data.base64EncodedString(),
        "timestamp": Date().timeIntervalSince1970,
      ]

      try WCSession.default.updateApplicationContext(applicationContext)

      #if DEBUG
        print("✅ iOS: App configurations synced to Watch via background context")
        print("   → Configurations will sync even if watch app not running")
      #endif
    } catch {
      #if DEBUG
        print("❌ iOS: Failed to sync app configurations: \(error.localizedDescription)")
      #endif
    }
  }
}
