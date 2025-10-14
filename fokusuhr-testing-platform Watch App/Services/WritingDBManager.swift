//
//  DataStorageManager.swift
//  FokusUhr Watch App
//
//  Created by Julian Amacker on 25.01.2024.

import CoreMotion
import Foundation

// MARK: - Upload Service Protocol
/// Protocol to abstract upload functionality for easier testing.
protocol UploadService {
  func uploadDataToGoogleDrive(
    binaryData: Data,
    filename: String,
    folderid: String,
    completion: @escaping (Result<URL, Error>) -> Void
  )
}

// MARK: - AccelerometerRecord Struct
/// Represents a single record of accelerometer data with a timestamp delta.
struct AccelerometerRecord {
  /// The time difference in milliseconds from the start of the recording session.
  let deltaTimestamp: UInt32
  /// The acceleration value on the x-axis, scaled.
  let x: Int16
  /// The acceleration value on the y-axis, scaled.
  let y: Int16
  /// The acceleration value on the z-axis, scaled.
  let z: Int16
}

// MARK: - DataStorageManager Class
/// Manages all data persistence, including creating and updating local JSON files,
/// fetching recorded accelerometer data, and uploading data to external services like Google Drive and a custom webhook.
/// It also handles a retry mechanism for failed uploads.
class DataStorageManager: UploadService {

  /// A `CMSensorRecorder` instance used for fetching historical accelerometer data.
  private var sensorRecorder = CMSensorRecorder()

  /// Service used to handle file uploads.
  ///
  /// - By default, this is set to `self`, so the class uses its built-in
  ///   `uploadDataToGoogleDrive` implementation.
  /// - In **unit tests**, you can assign a custom `UploadService` (e.g., `MockUploadService`)
  ///   to test upload and error handling **without real Google Drive uploads**.
  /// - The property is declared as `internal private(set)`:
  ///   - It can be **overridden in the same module or in tests** (via `@testable import`)
  ///   - It cannot be modified from outside the module in normal usage
  internal var uploadService: UploadService!

  /// Initializes the DataStorageManager.
  ///
  /// - Sets `uploadService` to `self` so that the default implementation is used.
  /// - In **unit tests**, you can override `uploadService` after initialization
  ///   to inject a mock service for testing.
  init() {
    self.uploadService = self  // ✅ Jetzt geht es
  }

  // MARK: - Constants for Folder IDs
  /// The Google Drive folder ID for storing binary (.bin) sensor data files.
  private let folderIDBin = GoogleDB.data_folder
  /// The Google Drive folder ID for storing JSON session log and configuration files.
  private let folderIDJSON = GoogleDB.config_log_folder

  // MARK: - FailedUpload Struct
  /// A struct to represent a file that failed to upload, allowing it to be retried later.
  struct FailedUpload: Codable, Identifiable, Hashable {
    /// A unique identifier for the failed upload, derived from the filename.
    let id: String
    /// The string representation of the local file URL for the failed upload.
    let fileURLString: String

    init(fileURLString: String) {
      self.fileURLString = fileURLString
      self.id = URL(string: fileURLString)?.lastPathComponent ?? ""
    }
  }

  // MARK: - Session JSON Handling

  /// Creates a new session JSON file locally with the provided data.
  /// - Parameters:
  ///   - data: A dictionary containing the session data.
  ///   - filename: The name for the new JSON file.
  ///   - completion: A result handler indicating success or failure.
  func createSessionJSON(
    data: [String: Any], filename: String, completion: @escaping (Result<Void, Error>) -> Void
  ) {
    DispatchQueue.global(qos: .background).async {
      do {
        let jsonData = try JSONSerialization.data(withJSONObject: data, options: [.prettyPrinted])
        let fileURL = self.getDocumentsDirectory().appendingPathComponent(filename)
        try jsonData.write(to: fileURL)
        DispatchQueue.main.async {
          completion(.success(()))
        }
      } catch {
        DispatchQueue.main.async {
          completion(.failure(error))
        }
      }
    }
  }

  /// Updates an existing session JSON file locally with new data.
  /// - Parameters:
  ///   - data: A dictionary containing the data to update the file with.
  ///   - filename: The name of the JSON file to update.
  ///   - completion: A result handler indicating success or failure.
  func updateSessionJSON(
    data: [String: Any], filename: String, completion: @escaping (Result<Void, Error>) -> Void
  ) {
    DispatchQueue.global(qos: .background).async {
      do {
        let jsonData = try JSONSerialization.data(withJSONObject: data, options: [.prettyPrinted])
        let fileURL = self.getDocumentsDirectory().appendingPathComponent(filename)
        try jsonData.write(to: fileURL)
        DispatchQueue.main.async {
          completion(.success(()))
        }
      } catch {
        DispatchQueue.main.async {
          completion(.failure(error))
        }
      }
    }
  }

  /// Helper to get the documents directory URL.
  /// - Returns: The URL of the app's documents directory.
  internal func getDocumentsDirectory() -> URL {
    let fileManager = FileManager.default
    guard
      let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
    else {
      fatalError("Unable to access Documents directory")
    }
    return documentsDirectory
  }

  // MARK: - Data Fetching and Processing

  /// Fetches accelerometer data for a given session, processes it into a binary format, and uploads it.
  /// This method is modularized for better readability and testability.
  ///
  /// Workflow:
  /// 1. Loads and validates the session JSON file
  /// 2. Extracts start and end dates from the session data
  /// 3. Fetches and converts accelerometer data into a binary format
  /// 4. Uploads the binary data to Google Drive
  ///
  /// - Parameters:
  ///   - sessionFilename: The filename of the session's JSON file, used to extract start/end dates.
  ///   - completion: A result handler returning the URL of the uploaded binary file or an error.
  func fetchAndStoreAccelerometerData(
    sessionFilename: String, completion: @escaping (Result<URL, Error>) -> Void
  ) {
    DispatchQueue.global(qos: .userInitiated).async {

      // 1. Load JSON
      switch self.loadSessionJSON(filename: sessionFilename) {
      case .failure(let error):
        return self.completeOnMainQueue(completion, with: .failure(error))
      case .success(let json):

        // 2. Extract Dates
        switch self.extractSessionDates(from: json) {
        case .failure(let error):
          return self.completeOnMainQueue(completion, with: .failure(error))
        case .success(let (startDate, endDate)):

          // 3. Create Binary
          switch self.createAccelerometerBinary(start: startDate, end: endDate) {
          case .failure(let error):
            return self.completeOnMainQueue(completion, with: .failure(error))
          case .success(let binaryData):

            // 4. Upload
            self.uploadBinaryData(binaryData, sessionFilename: sessionFilename) { result in
              self.completeOnMainQueue(completion, with: result)
            }
          }
        }
      }
    }
  }

  // MARK: - Modularized Helper Methods (Internal for Testing)

  /// Loads and parses the session JSON file from the documents directory.
  /// - Parameter filename: The name of the session JSON file.
  /// - Returns: A `Result` with the parsed JSON dictionary or an `Error`.
  internal func loadSessionJSON(filename: String) -> Result<[String: Any], Error> {
    let sessionURL = getDocumentsDirectory().appendingPathComponent(filename)

    guard FileManager.default.fileExists(atPath: sessionURL.path) else {
      return .failure(error(with: "File not found at path \(sessionURL.path)"))
    }

    do {
      let data = try Data(contentsOf: sessionURL)
      if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
        return .success(json)
      } else {
        return .failure(error(with: "Invalid JSON format."))
      }
    } catch {
      return .failure(error)
    }
  }

  /// Extracts and validates the start and end dates from a session JSON dictionary.
  /// Adds a 4-second buffer to the end date.
  /// - Parameter json: The parsed session JSON.
  /// - Returns: A `Result` with `(startDate, adjustedEndDate)` or an `Error`.
  internal func extractSessionDates(from json: [String: Any]) -> Result<(Date, Date), Error> {
    guard let startDate = extractStartDate(from: json) else {
      return .failure(error(with: "Start Date missing in JSON."))
    }
    guard let endDate = extractEndDate(from: json) else {
      return .failure(error(with: "End Date missing in JSON."))
    }
    guard startDate < endDate else {
      return .failure(error(with: "Start date is not before end date."))
    }

    let adjustedEndDate = endDate.addingTimeInterval(4)  // 4 seconds buffer
    return .success((startDate, adjustedEndDate))
  }

  /// Fetches accelerometer data for a given time range and converts it to binary format.
  /// - Parameters:
  ///   - start: The start date of the session.
  ///   - end: The end date of the session (including buffer).
  /// - Returns: A `Result` with the binary data or an `Error`.
  internal func createAccelerometerBinary(start: Date, end: Date) -> Result<Data, Error> {
    guard CMSensorRecorder.isAccelerometerRecordingAvailable() else {
      return .failure(error(with: "Accelerometer recording not available."))
    }

    let binaryData = fetchAccelerometerData(for: [(start, end)])
    guard !binaryData.isEmpty else {
      return .failure(error(with: "No accelerometer data available."))
    }

    return .success(binaryData)
  }

  /// Uploads binary accelerometer data to Google Drive.
  /// - Parameters:
  ///   - binaryData: The binary accelerometer data to upload.
  ///   - sessionFilename: The original session JSON filename (used to derive the .bin filename).
  ///   - completion: A result handler with the uploaded file URL or an error.
  internal func uploadBinaryData(
    _ binaryData: Data, sessionFilename: String, completion: @escaping (Result<URL, Error>) -> Void
  ) {
    let filename = (sessionFilename as NSString).deletingPathExtension + ".bin"
    uploadService.uploadDataToGoogleDrive(
      binaryData: binaryData, filename: filename, folderid: folderIDBin, completion: completion)
  }

  // MARK: - Data Uploading

  /// Uploads all pending files (from the failed uploads list) to their respective remote destinations.
  /// It ensures `.bin` files are created for every `.json` if they don't exist.
  /// - Parameter completion: A result handler indicating overall success or failure.
  func uploadToDB(completion: @escaping (Result<Void, Error>) -> Void) {
    DispatchQueue.global(qos: .userInitiated).async {
      // 1. Retrieve failed uploads
      let failedUploads = self.getFailedUploads()
      guard !failedUploads.isEmpty else {
        print("No failed uploads to process.")
        completion(.success(()))
        return
      }

      let dispatchGroup = DispatchGroup()
      var uploadError: Error?

      // 2. Ensure all JSONs have a corresponding BIN file, creating it if necessary.
      for upload in failedUploads {
        let jsonFilename = upload.id  // Assuming `id` is the JSON filename

        let binFilename = (jsonFilename as NSString).deletingPathExtension + ".bin"
        let binFileURL = self.getDocumentsDirectory().appendingPathComponent(binFilename)

        if FileManager.default.fileExists(atPath: binFileURL.path) {
          // If .bin file exists, we assume it's ready for upload.
          // The actual upload happens in the `tryUploads` step.
          print("BIN file \(binFilename) already exists.")
        } else {
          // If .bin file does not exist, fetch and store it.
          let sessionFilename = jsonFilename
          print("json filename for bin: \(sessionFilename)")
          dispatchGroup.enter()
          self.fetchAndStoreAccelerometerData(sessionFilename: sessionFilename) { result in
            switch result {
            case .success(let url):
              print("Successfully fetched and stored accelerometer data: \(url.lastPathComponent)")
            case .failure(let error):
              if uploadError == nil {
                uploadError = error
              }
            }
            dispatchGroup.leave()
          }
        }
      }

      // 3. Retry uploading all files now that BIN files are confirmed to exist.
      dispatchGroup.enter()
      self.tryUploads { result in
        switch result {
        case .success(let urls):
          print("Successfully retried uploads for URLs: \(urls)")
        case .failure(let error):
          if uploadError == nil {
            uploadError = error
          }
        }
        dispatchGroup.leave()
      }

      // 4. Notify when all processing and uploading is complete.
      dispatchGroup.notify(queue: .main) {
        if let error = uploadError {
          completion(.failure(error))
        } else {
          completion(.success(()))
        }
      }
    }
  }

  /// Uploads data to a specific Google Drive folder. Handles both success and failure by logging the attempt.
  internal func uploadDataToGoogleDrive(
    binaryData: Data, filename: String, folderid: String,
    completion: @escaping (Result<URL, Error>) -> Void
  ) {
    self.uploadToGoogleDrive(
      data: binaryData,
      filename: filename,
      folderID: folderid
    ) { result in
      switch result {
      case .success:
        print("Binary data uploaded successfully to Google Drive.")
        self.storeSuccessUpload(data: binaryData, filename: filename)
        // Create a placeholder URL for success.
        if let url = URL(string: "https://drive.google.com/file/d/\(filename)") {
          completion(.success(url))
        } else {
          completion(.failure(self.error(with: "Failed to create URL for uploaded file.")))
        }
      case .failure(let error):
        print("Failed to upload binary data to Google Drive: \(error.localizedDescription)")
        self.storeFailedUpload(data: binaryData, filename: filename)
        completion(.failure(error))
      }
    }
  }

  /// Performs the multipart form upload request to the Google Drive API.
  func uploadToGoogleDrive(
    data: Data, filename: String, folderID: String,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    UserConfigs.getAccessToken { result in
      switch result {
      case .success(let accessToken):
        print("Received access token")
        guard
          let uploadURL = URL(
            string: "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart")
        else {
          completion(
            .failure(
              NSError(
                domain: "GoogleDriveUploadError", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid upload URL"])))
          return
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(
          "multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Metadata part of the request body
        let metadata: [String: Any] = [
          "name": filename,
          "parents": [folderID],  // Specify the target folder
        ]

        if let metadataPart = try? JSONSerialization.data(withJSONObject: metadata, options: []) {
          body.append("--\(boundary)\r\n".data(using: .utf8)!)
          body.append("Content-Type: application/json; charset=UTF-8\r\n\r\n".data(using: .utf8)!)
          body.append(metadataPart)
          body.append("\r\n".data(using: .utf8)!)
        }

        // File content part of the request body
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)

        // End boundary
        body.append("--\(boundary)--".data(using: .utf8)!)

        request.httpBody = body

        // Perform the URLSession task
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
          if let error = error {
            completion(.failure(error))
            return
          }

          if let httpResponse = response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode)
          {
            completion(.success(()))
          } else {
            let error = NSError(
              domain: "GoogleDriveUploadError", code: -1,
              userInfo: [NSLocalizedDescriptionKey: "Failed to upload data to Google Drive"])
            completion(.failure(error))
          }
        }
        task.resume()

      case .failure(let error):
        print("Failed to get access token for Google Drive: \(error.localizedDescription)")
        completion(.failure(error))
      }
    }
  }

  /// Uploads JSON data to a specified webhook endpoint.
  func uploadDataToWebhook(jsonData: Data, completion: @escaping (Result<Void, Error>) -> Void) {
    guard
      let uploadURL = URL(
        string: "https://europe-west6-schlautech001.cloudfunctions.net/focuswatch2doc")
    else {
      completion(
        .failure(
          NSError(
            domain: "WebhookUploadError", code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Invalid webhook URL"])))
      return
    }

    var request = URLRequest(url: uploadURL)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = jsonData

    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
      if let error = error {
        completion(.failure(error))
        return
      }

      if let httpResponse = response as? HTTPURLResponse,
        (200...299).contains(httpResponse.statusCode)
      {
        completion(.success(()))
      } else {
        let error = NSError(
          domain: "WebhookUploadError", code: -1,
          userInfo: [NSLocalizedDescriptionKey: "Failed to upload JSON payload to webhook"])
        completion(.failure(error))
      }
    }
    task.resume()
  }

  /// Uploads a live state update to the webhook for real-time tracking.
  ///
  /// - Serializes the provided `stateEntries` to JSON.
  /// - Combines the JSON with the device ID and date string to form a single payload.
  /// - Sends the payload as a POST request to the live-tracking webhook.
  /// - Calls the completion handler with `.success` or `.failure` depending on the response.
  ///
  /// - Parameters:
  ///   - stateEntries: An array of recorded state history entries to send.
  ///   - deviceID: A unique identifier for the device sending the live update.
  ///   - dateString: A formatted timestamp string for the live update.
  ///   - completion: A result handler with `Void` on success or an `Error` on failure.
  func uploadLive(
    stateEntries: [WritingExerciseManager.StateHistoryEntry], deviceID: String, dateString: String,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    print("Live upload called")
    do {
      let encoder = JSONEncoder()
      encoder.dateEncodingStrategy = .iso8601
      let stateEntryJSON = try encoder.encode(stateEntries)
      let stateEntryObject = try JSONSerialization.jsonObject(with: stateEntryJSON, options: [])

      // Create the payload for the live upload.
      let combinedData: [String: Any] = [
        "ID": deviceID,
        "date": dateString,
        "stateHistory": stateEntryObject,
      ]

      let jsonData = try JSONSerialization.data(withJSONObject: combinedData, options: [])
      print(combinedData)

      // Upload the data to the webhook.
      self.uploadDataToWebhook(jsonData: jsonData) { result in
        switch result {
        case .success:
          print("Live upload succeeded for state change.")
          completion(.success(()))
        case .failure(let error):
          print("Live upload failed: \(error.localizedDescription)")
          completion(.failure(error))
        }
      }
    } catch {
      print("Failed to serialize state entry to JSON: \(error.localizedDescription)")
      completion(.failure(error))
    }
  }

  // MARK: - Failed Uploads Management

  /// Attempts to retry all uploads in the failed uploads list.
  ///
  /// - Iterates through all files stored in `FailedUploads` in UserDefaults.
  /// - For each file:
  ///   1. Checks if the file still exists in the documents directory.
  ///   2. Retries the upload to Google Drive in a background thread.
  ///   3. Removes the file from the failed list if the upload succeeds.
  /// - Supports `.json` and `.bin` files only; unsupported types are skipped.
  /// - Calls the completion handler with all successfully uploaded URLs or the first error encountered.
  ///
  /// - Parameter completion: A result handler with `[URL]` for all successfully re-uploaded files, or an `Error` if any upload failed.
  func tryUploads(completion: @escaping (Result<[URL], Error>) -> Void) {
    let failedUploads = getFailedUploads()
    guard !failedUploads.isEmpty else {
      print("No failed uploads to retry.")
      completion(.success([]))
      return
    }

    print("Retrying \(failedUploads.count) failed uploads.")

    let dispatchGroup = DispatchGroup()
    var retryError: Error?
    var retryUploadedURLs: [URL] = []
    let syncQueue = DispatchQueue(label: "com.yourapp.retrySyncQueue")  // For thread-safe access to shared variables

    for upload in failedUploads {
      guard let fileURL = URL(string: upload.fileURLString) else {
        print("Invalid fileURL string: \(upload.fileURLString)")
        continue
      }

      guard FileManager.default.fileExists(atPath: fileURL.path) else {
        print("File does not exist at path: \(fileURL.path)")
        self.removeFailedUpload(fileURL: fileURL)
        continue
      }

      dispatchGroup.enter()

      do {
        let data = try Data(contentsOf: fileURL)
        let filename = fileURL.lastPathComponent
        let fileExtension = fileURL.pathExtension.lowercased()

        // Determine where to upload based on file extension.
        switch fileExtension {
        case "bin":
          self.uploadDataToGoogleDrive(
            binaryData: data, filename: filename, folderid: self.folderIDBin
          ) { result in
            syncQueue.async {
              switch result {
              case .success(let url):
                retryUploadedURLs.append(url)
                print("Successfully re-uploaded .bin file to Google Drive: \(filename)")
                self.removeFailedUpload(fileURL: fileURL)
              case .failure(let error):
                print("Failed to re-upload .bin file to Google Drive: \(filename), error: \(error)")
                if retryError == nil { retryError = error }
              }
              dispatchGroup.leave()
            }
          }
        case "json":
          self.uploadDataToGoogleDrive(
            binaryData: data, filename: filename, folderid: self.folderIDJSON
          ) { result in
            syncQueue.async {
              switch result {
              case .success(let url):
                retryUploadedURLs.append(url)
                print("Successfully re-uploaded .json file to Google Drive: \(filename)")
                self.removeFailedUpload(fileURL: fileURL)
              case .failure(let error):
                print(
                  "Failed to re-upload .json file to Google Drive: \(filename), error: \(error)")
                if retryError == nil { retryError = error }
              }
              dispatchGroup.leave()
            }
          }
        default:
          print("Unsupported file type for file: \(filename). Skipping.")
          dispatchGroup.leave()
        }
      } catch {
        print("Failed to read data for re-upload from file: \(fileURL.path), error: \(error)")
        dispatchGroup.leave()
      }
    }

    dispatchGroup.notify(queue: .main) {
      if let error = retryError {
        completion(.failure(error))
      } else {
        completion(.success(retryUploadedURLs))
      }
    }
  }

  /// Retrieves the current list of failed uploads stored in UserDefaults.
  ///
  /// - The list contains files that previously failed to upload to Google Drive.
  /// - Each entry includes the file URL and an ID derived from the filename.
  /// - If no data is stored or decoding fails, this method returns an empty array.
  ///
  /// - Returns: An array of `FailedUpload` entries representing the current retry queue.
  func getFailedUploads() -> [FailedUpload] {
    if let data = UserDefaults.standard.data(forKey: "FailedUploads"),
      let uploads = try? JSONDecoder().decode([FailedUpload].self, from: data)
    {
      return uploads
    }
    return []
  }

  /// Saves the list of failed uploads to UserDefaults.
  private func saveFailedUploads(_ uploads: [FailedUpload]) {
    if let encoded = try? JSONEncoder().encode(uploads) {
      UserDefaults.standard.set(encoded, forKey: "FailedUploads")
    } else {
      print("Failed to encode FailedUpload.")
    }
  }

  /// Stores a file locally and adds it to the failed uploads list for retry.
  ///
  /// - Writes the provided data to the documents directory under the given filename.
  /// - Adds a `FailedUpload` entry to UserDefaults so it can be retried later.
  /// - If the file is already in the failed uploads list, it is not duplicated.
  ///
  /// - Parameters:
  ///   - data: The file data to save locally.
  ///   - filename: The filename under which to save the file in the documents directory.
  private func storeFailedUpload(data: Data, filename: String) {
    var failedUploads = getFailedUploads()

    // Prevent duplicates in the failed list.
    let fileAlreadyExists = failedUploads.contains { $0.fileURLString.hasSuffix(filename) }
    guard !fileAlreadyExists else {
      print("File \(filename) is already in the failed uploads list. Skipping storage.")
      return
    }

    // Save the data to a local file.
    let storeResult = storeDataToFile(data: data, filename: filename)

    switch storeResult {
    case .success(let fileURL):
      print("Data stored locally for later upload: \(fileURL)")

      // Add the new entry to the failed uploads list.
      let upload = FailedUpload(fileURLString: fileURL.absoluteString)
      failedUploads.append(upload)

      saveFailedUploads(failedUploads)

      print("Stored upload info: \(upload)")
      print("Updated FailedUploads count: \(failedUploads.count)")

    case .failure(let error):
      print("Failed to store data locally: \(error)")
    }
  }

  /// Adds an existing file to the failed uploads list for future retry.
  ///
  /// - Checks if the file exists in the documents directory.
  /// - Avoids adding duplicates if the file is already in the list.
  /// - Updates the `FailedUploads` list in UserDefaults.
  ///
  /// - Parameter filename: The name of the file (in the documents directory) to mark for retry.
  func addToUploads(filename: String) {
    var failedUploads = getFailedUploads()

    let fileAlreadyExists = failedUploads.contains { $0.fileURLString.hasSuffix(filename) }
    guard !fileAlreadyExists else {
      print("File \(filename) is already in the failed uploads list. Skipping storage.")
      return
    }

    let fileManager = FileManager.default
    guard
      let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
    else {
      print("Failed to retrieve documents directory.")
      return
    }
    let fileURL = documentsDirectory.appendingPathComponent(filename)

    guard fileManager.fileExists(atPath: fileURL.path) else {
      print(
        "File \(filename) does not exist at path: \(fileURL.path). Cannot add to failed uploads.")
      return
    }

    let upload = FailedUpload(fileURLString: fileURL.absoluteString)
    failedUploads.append(upload)

    saveFailedUploads(failedUploads)

    print("Stored upload info: \(upload)")
    print("Updated FailedUploads count: \(failedUploads.count)")
  }

  /// Stores a successfully uploaded file locally for archival purposes.
  ///
  /// - Saves the file in the documents directory under the specified filename.
  /// - If the file already exists locally, the method skips saving.
  /// - This does **not** affect the `FailedUploads` list.
  ///
  /// - Parameters:
  ///   - data: The file data to save locally.
  ///   - filename: The filename for the local archive copy.
  private func storeSuccessUpload(data: Data, filename: String) {
    let fileManager = FileManager.default
    guard
      let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
    else {
      print("Failed to access documents directory.")
      return
    }

    let fileURL = documentsDirectory.appendingPathComponent(filename)

    if fileManager.fileExists(atPath: fileURL.path) {
      print("File \(filename) is already stored locally. Skipping storage.")
      return
    }

    let storeResult = storeDataToFile(data: data, filename: filename)

    switch storeResult {
    case .success(let fileURL):
      print("Data stored locally for archive: \(fileURL)")
    case .failure(let error):
      print("Failed to store data locally: \(error)")
    }
  }

  /// Removes a specific entry from the failed uploads list in UserDefaults.
  private func removeFailedUpload(fileURL: URL) {
    var failedUploads = getFailedUploads()
    failedUploads.removeAll { $0.fileURLString == fileURL.absoluteString }
    saveFailedUploads(failedUploads)
    print("Successfully removed file entry: \(fileURL.lastPathComponent)")
  }

  // MARK: - Utility Methods

  /// Fetches raw accelerometer data from the `CMSensorRecorder` for given time intervals.
  private func fetchAccelerometerData(for intervals: [(start: Date, end: Date)]) -> Data {
    var binaryData = Data()

    for interval in intervals {
      if let dataList = sensorRecorder.accelerometerData(from: interval.start, to: interval.end) {
        for case let data as CMRecordedAccelerometerData in dataList {
          let deltaTimestamp = self.calculateDeltaTimestamp(for: data, start: interval.start)
          let record = AccelerometerRecord(
            deltaTimestamp: deltaTimestamp,
            x: Int16(data.acceleration.x * 4096),
            y: Int16(data.acceleration.y * 4096),
            z: Int16(data.acceleration.z * 4096)
          )
          binaryData.append(self.encodeRecord(record))
        }
      }
    }

    return binaryData
  }

  /// Calculates the time difference in milliseconds between a data point and the session start time.
  private func calculateDeltaTimestamp(for data: CMRecordedAccelerometerData, start: Date) -> UInt32
  {
    let timestamp = data.startDate.timeIntervalSince1970 * 1000  // milliseconds
    let startTimestamp = start.timeIntervalSince1970 * 1000
    let deltaTime = max(0, timestamp - startTimestamp)
    return UInt32(deltaTime)
  }

  /// Encodes an `AccelerometerRecord` struct into raw `Data`.
  private func encodeRecord(_ record: AccelerometerRecord) -> Data {
    var data = Data()
    withUnsafeBytes(of: record.deltaTimestamp) { data.append(contentsOf: $0) }
    withUnsafeBytes(of: record.x) { data.append(contentsOf: $0) }
    withUnsafeBytes(of: record.y) { data.append(contentsOf: $0) }
    withUnsafeBytes(of: record.z) { data.append(contentsOf: $0) }
    return data
  }

  /// Writes raw `Data` to a file in the documents directory.
  private func storeDataToFile(data: Data, filename: String) -> Result<URL, Error> {
    let fileURL = getDocumentsDirectory().appendingPathComponent(filename)

    do {
      try data.write(to: fileURL)
      print("Successfully wrote data to \(fileURL)")
      return .success(fileURL)
    } catch {
      print("Error writing data to file: \(error)")
      return .failure(error)
    }
  }

  /// Extracts and parses the start date from a session's JSON data.
  private func extractStartDate(from json: [String: Any]) -> Date? {
    if let startDateString = json["date"] as? String {
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
      dateFormatter.timeZone = TimeZone(identifier: "Europe/Zurich")
      return dateFormatter.date(from: startDateString)
    }
    return nil
  }

  /// Extracts and parses the end date from a session's JSON data.
  private func extractEndDate(from json: [String: Any]) -> Date? {
    if let endDateString = json["SessionEndDate"] as? String {
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
      dateFormatter.timeZone = TimeZone(identifier: "Europe/Zurich")
      return dateFormatter.date(from: endDateString)
    }
    return nil
  }

  /// Helper to ensure a completion handler is called on the main thread.
  private func completeOnMainQueue<T>(
    _ completion: @escaping (Result<T, Error>) -> Void, with result: Result<T, Error>
  ) {
    DispatchQueue.main.async {
      completion(result)
    }
  }

  /// Creates a custom `NSError` object.
  private func error(with message: String) -> NSError {
    return NSError(
      domain: "DataStorageManagerError", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
  }
}
