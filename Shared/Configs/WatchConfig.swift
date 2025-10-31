import Foundation
import KeychainAccess

class WatchConfig {
  static let shared = WatchConfig()
  
  private let keychain = Keychain(service: "com.fokusapp.FokusWatch.watchkitapp")
  private let sharedDefaults = UserDefaults(suiteName: "group.net.com.fokusuhr")
  
  private init() {}
  
  var uuid: String {
    if let sharedUUID = sharedDefaults?.string(forKey: "deviceUUID"), !sharedUUID.isEmpty {
      #if DEBUG
        print("📱 WatchConfig: Found shared UUID: \(String(sharedUUID.prefix(8)))")
      #endif
      return sharedUUID
    }
    
    let deviceUUID: String
    if let retrievedUUID = try? keychain.getString("deviceUUID") {
      #if DEBUG
        print("📱 WatchConfig: Found Keychain UUID: \(String(retrievedUUID.prefix(8)))")
      #endif
      deviceUUID = retrievedUUID
    } else {
      let newUUID = UUID().uuidString
      try? keychain.set(String(newUUID), key: "deviceUUID")
      #if DEBUG
        print("📱 WatchConfig: Generated NEW UUID: \(String(newUUID.prefix(8)))")
      #endif
      deviceUUID = newUUID
    }
    storeDeviceIDInUserDefaults(deviceUUID)
    return deviceUUID
  }
  
  func storeDeviceIDInUserDefaults(_ deviceID: String) {
    sharedDefaults?.set(deviceID, forKey: "deviceUUID")
    sharedDefaults?.synchronize()
    #if DEBUG
      print("📱 WatchConfig storing deviceUUID: \(deviceID)")
      print("📱 Verification read: \(sharedDefaults?.string(forKey: "deviceUUID") ?? "nil")")
    #endif
  }
}
