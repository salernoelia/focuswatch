//
//  ConfigManager.swift
//  FokusUhr Watch App
//
//  Created by Julian Amacker on 18.01.2024.
//

import Foundation
import KeychainAccess
import WatchKit

// MARK: - Config Struct
/// Represents the user-configurable settings for the application.
/// This includes timers for different states, feedback intervals, and model parameters.
struct Config: Codable {
  // MARK: - Properties

  /// The duration of the learning/working period in minutes.
  var learn: Double = 5.0
  /// The duration of the thinking period in minutes.
  var think: Double = 0.3
  /// The duration of the pause period in minutes.
  var pause: Double = 1.0
  /// The number of work/pause repetitions in a session.
  var repetitions: Int = 3
  /// The interval in seconds for providing positive feedback.
  var posFBIntveral: Int = 30
  /// The interval in seconds for providing negative feedback.
  var negFBInterval: Int = 10
  /// A flag to enable or disable all haptic feedback.
  var feedbackEnabled: Bool = true
  /// The user's email address.
  var email: String = ""
  /// The user's username.
  var username: String = ""
  /// A flag to determine whether to use the simple EMA model or a more complex ML model.
  var emaModel: Bool = true
  /// A nested struct containing parameters for the activity detection model.
  var modelParams: ModelParams = ModelParams()

  // MARK: - Public Methods

  /// Converts the `Config` instance into a dictionary.
  /// - Throws: An error if the serialization fails.
  /// - Returns: A `[String: Any]` representation of the configuration.
  func toDictionary() throws -> [String: Any] {
    let encoder = JSONEncoder()
    let data = try encoder.encode(self)
    let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])

    guard let dictionary = jsonObject as? [String: Any] else {
      throw NSError(
        domain: "ConfigSerialization", code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Failed to convert JSON to [String: Any]"])
    }
    return dictionary
  }
}

// MARK: - AccelerometerVector Struct
/// A struct to represent a 3D vector, primarily for accelerometer data.
/// Note: Marked as unused in version 2.0.
struct AccelerometerVector: Codable {
  var x: Double = 0.009
  var y: Double = 0.985
  var z: Double = -0.56

  /// Calculates the normalized version of the vector (unit vector).
  /// - Parameter correctOrientation: A boolean flag that was intended to adjust for device orientation (now unused).
  /// - Returns: A new `AccelerometerVector` with a magnitude of 1.
  func normalized(correctOrientation: Bool) -> AccelerometerVector {
    let _ = correctOrientation  // Parameter is unused.
    let magnitude = sqrt(x * x + y * y + z * z)
    guard magnitude != 0 else { return AccelerometerVector(x: 0, y: 0, z: 0) }
    let res = AccelerometerVector(x: x / magnitude, y: y / magnitude, z: z / magnitude)
    return res
  }

  /// Adds two vectors together.
  static func + (lhs: AccelerometerVector, rhs: AccelerometerVector) -> AccelerometerVector {
    return AccelerometerVector(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
  }

  /// Divides a vector by a scalar value.
  static func / (lhs: AccelerometerVector, rhs: Double) -> AccelerometerVector {
    guard rhs != 0 else { return AccelerometerVector(x: 0, y: 0, z: 0) }
    return AccelerometerVector(x: lhs.x / rhs, y: lhs.y / rhs, z: lhs.z / rhs)
  }

  /// Calculates the dot product of this vector with another.
  func dotProduct(with rhs: AccelerometerVector) -> Double {
    return self.x * rhs.x + self.y * rhs.y + self.z * rhs.z
  }
}

// MARK: - GoogleDB Struct
/// A container for static string constants representing Google Drive folder IDs.
struct GoogleDB {
  // Config folder not used anymore
  // static let config_folder: String = "1voOQiyndC5VEGhpbRgXrzszt7t_gzM9d"
  static let data_folder: String = "1fzd0ibjS4wpKxlNU62MZNwKA5DjtLZMk"
  static let config_log_folder: String = "1g_uEvDzQuN7xIBvXqdy0e2F00QjQoNJk"
  static let statehistory_folder: String = "1mC2HiVRhur-Txt9MY-Ph4ToeS8-YCHvl"
}

// MARK: - UserConfigs Class

// MARK: - UserConfigs Class
/// An observable object that manages the lifecycle of the user's configuration (`Config`).
/// It handles loading from `UserDefaults` and syncing with `AppConfigurations`.
class UserConfigs: ObservableObject {
  // MARK: - Properties

  /// The shared singleton instance.
  static let shared = UserConfigs()

  /// The currently active configuration, published to update the UI upon changes.
  @Published var configs = Config()

  /// A prefix of the device's UUID, used for naming configuration files.
  let deviceUUIDPrefix = WatchConfig.shared.uuid.prefix(6)

  // MARK: - Initializer

  init() {
    // Load existing config or fallback to default upon initialization.
    self.loadConfigs()

    // Listen for updates from SyncCoordinator
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleAppConfigurationsUpdate(_:)),
      name: .appConfigurationsUpdated,
      object: nil
    )
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  // MARK: - Configuration Management

  /// Loads configurations from `UserDefaults`.
  /// - Parameter completion: An optional closure to be executed after loading is complete.
  func loadConfigs(completion: (() -> Void)? = nil) {
    if let config = UserConfigs.loadConfigFromUserDefaults(forKey: "config_\(deviceUUIDPrefix)") {
      // If a config is found locally, load it.
      DispatchQueue.main.async {
        self.configs = config
        print("Configs loaded from UserDefaults: \(self.configs)")
        completion?()
      }
    } else {
      // If not found locally, use default.
      DispatchQueue.main.async {
        self.configs = Config()
        print("Configs default (no local config found)")
        completion?()
      }
    }
  }

  /// Resets the configuration by removing it from `UserDefaults` and reloading.
  func resetConfigs() {
    UserDefaults.standard.removeObject(forKey: "config_\(deviceUUIDPrefix)")
    loadConfigs()
  }

  /// A static method to load a `Config` object from `UserDefaults`.
  /// - Parameter key: The key under which the configuration is stored.
  /// - Returns: An optional `Config` object.
  static func loadConfigFromUserDefaults(forKey key: String) -> Config? {
    guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
    let decoder = JSONDecoder()
    return try? decoder.decode(Config.self, from: data)
  }

  /// Stores a `Config` object into `UserDefaults`.
  /// - Parameters:
  ///   - config: The `Config` object to store.
  ///   - key: The key to store the configuration under.
  func storeConfigInUserDefaults(config: Config, forKey key: String) {
    if let encoded = try? JSONEncoder().encode(config) {
      UserDefaults.standard.set(encoded, forKey: key)
    }
  }

  // MARK: - Sync Handling

  @objc private func handleAppConfigurationsUpdate(_ notification: Notification) {
    guard let appConfigs = notification.object as? AppConfigurations else { return }
    let writingConfig = appConfigs.writing

    DispatchQueue.main.async {
      print(" Updating Writing config from AppConfigurations...")

      // Update properties from shared configuration
      self.configs.learn = writingConfig.workMinutes
      self.configs.think = writingConfig.thinkMinutes
      self.configs.pause = writingConfig.pauseMinutes
      self.configs.repetitions = writingConfig.repetitions

      // Map vibration settings if needed, or keep existing logic
      // For now we only map the main timing parameters as requested

      // Save the updated config
      self.storeConfigInUserDefaults(
        config: self.configs, forKey: "config_\(self.deviceUUIDPrefix)")
      print("Writing config updated: \(self.configs)")
    }
  }
}
