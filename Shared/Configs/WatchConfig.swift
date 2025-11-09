import Foundation
import KeychainAccess

class WatchConfig {
  static let shared = WatchConfig()

  private let keychain = Keychain(service: "com.fokusapp.FokusWatch.watchkitapp")

  private init() {}

  var uuid: String {
    #if os(watchOS)
      if let retrievedUUID = try? keychain.getString("deviceUUID") {
        #if DEBUG
          print("⌚ WatchConfig: Found Keychain UUID: \(String(retrievedUUID.prefix(8)))")
        #endif
        syncToSharedContainer(retrievedUUID)
        return retrievedUUID
      } else {
        let newUUID = UUID().uuidString
        try? keychain.set(String(newUUID), key: "deviceUUID")
        #if DEBUG
          print("⌚ WatchConfig: Generated NEW UUID: \(String(newUUID.prefix(8)))")
        #endif
        syncToSharedContainer(newUUID)
        return newUUID
      }
    #else
      if let connectedWatchUUID = UserDefaults.standard.string(forKey: "connectedWatchUUID") {
        #if DEBUG
          print("📱 WatchConfig: Connected Watch UUID: \(String(connectedWatchUUID.prefix(8)))")
        #endif
        return connectedWatchUUID
      }
      #if DEBUG
        print("📱 WatchConfig: No watch connected yet")
      #endif
      return "NOT-CONNECTED"
    #endif
  }

  #if os(watchOS)
    private func syncToSharedContainer(_ uuid: String) {
      let sharedDefaults = UserDefaults(suiteName: "group.net.com.fokusuhr")
      sharedDefaults?.set(uuid, forKey: "deviceUUID")
      sharedDefaults?.synchronize()

      #if DEBUG
        print("⌚ WatchConfig: Synced UUID to shared container: \(String(uuid.prefix(8)))")
      #endif
    }
  #endif

  #if !os(watchOS)
    static let watchUUIDDidChangeNotification = Notification.Name("WatchUUIDDidChange")

    func setConnectedWatchUUID(_ uuid: String) {
      let currentUUID = UserDefaults.standard.string(forKey: "connectedWatchUUID")

      UserDefaults.standard.set(uuid, forKey: "connectedWatchUUID")

      DispatchQueue.main.async {
        NotificationCenter.default.post(
          name: WatchConfig.watchUUIDDidChangeNotification, object: uuid)
        NotificationCenter.default.post(name: UserDefaults.didChangeNotification, object: nil)
      }

      #if DEBUG
        if currentUUID != uuid {
          print(
            "📱 WatchConfig: Updated connected watch UUID from \(currentUUID ?? "none") to \(String(uuid.prefix(8)))"
          )
        } else {
          print("📱 WatchConfig: Confirmed watch UUID: \(String(uuid.prefix(8)))")
        }
      #endif
    }
  #endif
}
