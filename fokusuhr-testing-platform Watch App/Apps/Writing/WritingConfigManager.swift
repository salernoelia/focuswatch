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
            throw NSError(domain: "ConfigSerialization", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert JSON to [String: Any]"])
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
    func normalized(correctOrientation:Bool) -> AccelerometerVector {
        let _ = correctOrientation // Parameter is unused.
        let magnitude = sqrt(x*x + y*y + z*z)
        guard magnitude != 0 else { return AccelerometerVector(x: 0, y: 0, z: 0) }
        let res = AccelerometerVector(x: x/magnitude, y: y/magnitude, z: z/magnitude)
        return res
    }
    
    /// Adds two vectors together.
    static func +(lhs: AccelerometerVector, rhs: AccelerometerVector) -> AccelerometerVector {
        return AccelerometerVector(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }
    
    /// Divides a vector by a scalar value.
    static func /(lhs: AccelerometerVector, rhs: Double) -> AccelerometerVector {
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
    static let config_folder: String = "1voOQiyndC5VEGhpbRgXrzszt7t_gzM9d"
    static let data_folder: String = "1fzd0ibjS4wpKxlNU62MZNwKA5DjtLZMk"
    static let config_log_folder: String = "1g_uEvDzQuN7xIBvXqdy0e2F00QjQoNJk"
    static let statehistory_folder: String = "1mC2HiVRhur-Txt9MY-Ph4ToeS8-YCHvl"
}

// MARK: - AccessServer Struct
/// A container for static credentials used to access a token-providing server.
struct AccessServer {
    static let username = "julama"
    static let password = "xm7f5aqxoRmFgFutM1mw9sf93QtQoA5"
}

// MARK: - UserConfigs Class
/// An observable object that manages the lifecycle of the user's configuration (`Config`).
/// It handles loading from `UserDefaults`, fetching from a remote server (Google Drive), and saving updates.
class UserConfigs: ObservableObject {
    // MARK: - Properties
    
    /// The shared singleton instance.
    static let shared = UserConfigs()
    
    /// The currently active configuration, published to update the UI upon changes.
    @Published var configs = Config()
    
    /// A prefix of the device's UUID, used for naming configuration files.
    let deviceUUIDPrefix = WatchConfig.shared.uuid.prefix(6)
    
    /// The Google Drive folder ID where configurations are stored.
    let configFolder = GoogleDB.config_folder
    
    // MARK: - Initializer
    
    init() {
        // Load existing config or fallback to default upon initialization.
        self.loadConfigs()
    }
    
    // MARK: - Configuration Management
    
    /// Loads configurations, prioritizing local `UserDefaults` and falling back to a network fetch.
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
            // If not found locally, fetch from the remote server.
            fetchAndStoreConfigs(folderId: configFolder, deviceIdPrefix: String(deviceUUIDPrefix)) { [weak self] in
                guard let self = self else { return }
                // After fetching, try loading from UserDefaults again.
                DispatchQueue.main.async {
                    if let fetchedConfig = UserConfigs.loadConfigFromUserDefaults(forKey: "config_\(self.deviceUUIDPrefix)") {
                        self.configs = fetchedConfig
                        print("Configs loaded from DB")
                    } else {
                        self.configs = Config() // Fallback to default if fetch also fails.
                        print("Configs default")
                    }
                    print("Device ID Prefix: \(self.deviceUUIDPrefix)")
                    print("Configuration in use: \(self.configs)")
                    completion?()
                }
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

    // MARK: - Network Operations
    
    /// Fetches a configuration file from Google Drive and stores it in `UserDefaults`.
    /// - Parameters:
    ///   - folderId: The ID of the folder to search in.
    ///   - deviceIdPrefix: The device ID prefix to identify the correct config file.
    ///   - completion: A closure to be executed after the operation is complete.
    func fetchAndStoreConfigs(folderId: String, deviceIdPrefix: String, completion: @escaping () -> Void) {
        // First, get an access token.
        UserConfigs.getAccessToken { result in
            switch result {
            case .success(let accessToken):
                // Construct the query to find the specific config file.
                let query = "name contains 'config_\(deviceIdPrefix).json' and '\(folderId)' in parents"
                let urlString = "https://www.googleapis.com/drive/v3/files?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
                
                guard let url = URL(string: urlString) else {
                    print("Invalid URL")
                    completion()
                    return
                }
                
                var request = URLRequest(url: url)
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                
                URLSession.shared.dataTask(with: request) { data, response, error in
                    guard let data = data, error == nil else {
                        print("Network error: \(error?.localizedDescription ?? "Unknown error")")
                        completion()
                        return
                    }
                    
                    do {
                        let decoder = JSONDecoder()
                        let filesResponse = try decoder.decode(GoogleDriveFilesResponse.self, from: data)
                        if filesResponse.files.isEmpty {
                            print("No config files found.")
                            completion()
                            return
                        }
                        
                        // If a file is found, download its content.
                        self.downloadFile(withId: filesResponse.files[0].id, accessToken: accessToken) { jsonData in
                            if let jsonData = jsonData,
                               let config = try? JSONDecoder().decode(Config.self, from: jsonData) {
                                print("Downloaded config: \(config)")
                                DispatchQueue.main.async {
                                    // Store the downloaded config locally.
                                    self.storeConfigInUserDefaults(config: config, forKey: "config_\(deviceIdPrefix)")
                                    self.configs = config
                                }
                            }
                            completion()
                        }
                    } catch {
                        print("JSON decoding error: \(error)")
                        completion()
                    }
                }.resume()
                
            case .failure(let error):
                print("Failed to fetch access token: \(error.localizedDescription)")
                completion()
            }
        }
    }
    
    /// Downloads a specific file's content from Google Drive.
    /// - Parameters:
    ///   - fileId: The ID of the file to download.
    ///   - accessToken: The OAuth 2.0 access token.
    ///   - completion: A closure that returns the file's data or nil.
    func downloadFile(withId fileId: String, accessToken: String, completion: @escaping (Data?) -> Void) {
        let downloadUrlString = "https://www.googleapis.com/drive/v3/files/\(fileId)?alt=media"
        guard let downloadUrl = URL(string: downloadUrlString) else {
            print("Invalid download URL")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: downloadUrl)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error downloading file: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            print("File content downloaded successfully")
            completion(data)
        }
        task.resume()
    }
    
    /// A static method to retrieve an OAuth 2.0 access token from a custom server.
    /// - Parameter completion: A result handler returning the access token string or an error.
    static func getAccessToken(completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "https://jabla.pythonanywhere.com/get_access_token") else {
            completion(.failure(NSError(domain: "URLCreationError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        // Use Basic Authentication to get the token.
        let username = AccessServer.username
        let password = AccessServer.password
        let loginString = "\(username):\(password)"
        
        guard let loginData = loginString.data(using: .utf8) else {
            completion(.failure(NSError(domain: "EncodingError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unable to encode credentials"])))
            return
        }
        let base64LoginString = loginData.base64EncodedString()
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "AccessTokenError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            if let accessToken = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                completion(.success(accessToken))
            } else {
                completion(.failure(NSError(domain: "AccessTokenError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to decode access token"])))
            }
        }.resume()
    }
    
    // MARK: - Nested Types for API Responses
    
    /// A struct to decode the list of files from a Google Drive API response.
    struct GoogleDriveFilesResponse: Codable {
        let files: [GoogleDriveFile]
    }
    
    /// A struct to decode a single file object from a Google Drive API response.
    struct GoogleDriveFile: Codable {
        let id: String
        let name: String
    }
}
