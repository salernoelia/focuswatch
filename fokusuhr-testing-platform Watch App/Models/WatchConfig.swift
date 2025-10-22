//
//  WatchConfig.swift
//  fokusuhr-testing-platform Watch App
//
//  Created by Elias on 22.10.25.
//

import Foundation
import KeychainAccess

/// A singleton class responsible for creating, storing, and retrieving a unique identifier for the device.
/// It uses `KeychainAccess` to securely store the UUID.
class WatchConfig {
    // MARK: - Properties
    
    /// The shared singleton instance.
    static let shared = WatchConfig()
    
    /// The Keychain service instance for secure storage.
    let keychain = Keychain(service: "com.fokusapp.FokusWatch.watchkitapp")

    /// A computed property that retrieves the UUID from the keychain.
    /// If no UUID exists, it creates a new one, saves it to the keychain, and returns it.
    var uuid: String {
        if let retrievedUUID = try? keychain.getString("deviceUUID") {
            return retrievedUUID
        } else {
            let newUUID = UUID().uuidString
            try? keychain.set(String(newUUID), key: "deviceUUID")
            storeDeviceIDInUserDefaults()
            return String(newUUID)
        }
    }
    
    // MARK: - Public Methods
    
    /// Stores the device UUID in shared `UserDefaults` to be accessible by app extensions (like widgets).
    func storeDeviceIDInUserDefaults() {
        let deviceID = self.uuid
        let sharedDefaults = UserDefaults(suiteName: "group.fokus.w")
        sharedDefaults?.set(deviceID, forKey: "deviceUUID")
        sharedDefaults?.synchronize()
        #if DEBUG
        print("📱 WatchConfig storing deviceUUID: \(deviceID)")
        print("📱 Verification read: \(sharedDefaults?.string(forKey: "deviceUUID") ?? "nil")")
        #endif
    }
}
