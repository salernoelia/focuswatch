import WatchConnectivity

extension Notification.Name {
  static let appConfigurationsUpdated = Notification.Name("appConfigurationsUpdated")
}

extension WatchConnector {

  func handleConfigurationsUpdate(from applicationContext: [String: Any]) {
    guard let base64String = applicationContext["appConfigurations"] as? String,
      let data = Data(base64Encoded: base64String)
    else {
      #if DEBUG
        print("⌚ Watch: Invalid configuration data received")
      #endif
      return
    }

    do {
      let configurations = try JSONDecoder().decode(AppConfigurations.self, from: data)
      UserDefaults.standard.set(data, forKey: "appConfigurations")

      #if DEBUG
        print("✅ Watch: App configurations updated")
      #endif

      NotificationCenter.default.post(name: .appConfigurationsUpdated, object: configurations)
    } catch {
      #if DEBUG
        print("❌ Watch: Failed to decode app configurations: \(error.localizedDescription)")
      #endif
    }
  }

  static func loadAppConfigurations() -> AppConfigurations {
    guard let data = UserDefaults.standard.data(forKey: "appConfigurations") else {
      return AppConfigurations.default
    }

    do {
      return try JSONDecoder().decode(AppConfigurations.self, from: data)
    } catch {
      #if DEBUG
        print("❌ Watch: Failed to load app configurations: \(error.localizedDescription)")
      #endif
      return AppConfigurations.default
    }
  }
}
