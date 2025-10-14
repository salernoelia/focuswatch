//
//  ConfigurationView.swift
//  FokusUhr Watch App
//
//  Created by Julian Amacker on 04.11.2024.

import Foundation
import SwiftUI

// MARK: - WritingConfigurationsView
/// A view that allows users to manage and view their application settings,
/// handle failed data uploads, and see device information.
/// TODO: RENAME
struct WritingConfigurationsView: View {
  // MARK: - Properties

  /// A binding to the current configuration object, allowing this view to modify it.
  @Binding var current_setting: Config

  /// The environment object that manages the overall state of the exercise session.
  @EnvironmentObject var WritingExerciseManager: WritingExerciseManager

  /// A prefix of the device's UUID for identification purposes.
  private let deviceUUIDPrefix = DeviceIdentifier.shared.uuid.prefix(6)

  /// A state object that holds the shared `UserConfigs` instance.
  @StateObject private var configs = UserConfigs.shared

  // State variables for the configuration picker sheet.
  @State private var learnValue: Int = 1
  @State private var pauseValue: Int = 1
  @State private var repetitionsValue: Int = 1
  @State private var showPickerSheet = false

  /// A flag indicating if the device storage is low.
  @State private var lowStorage = false

  /// An instance of the data storage manager to handle file operations.
  let dbManager = DataStorageManager()

  /// A state variable holding the list of failed uploads.
  @State private var failedUploads: [DataStorageManager.FailedUpload] = []

  // State variables for the file upload UI.
  @State private var availableFiles: [URL] = []
  @State private var selectedFile: URL?
  @State private var isLoading = false

  // State variables for displaying alerts to the user.
  @State private var alertTitle = ""
  @State private var alertMessage = ""
  @State private var showAlert = false

  /// A state variable to hold the count of failed uploads for display.
  @State private var number_of_failed_uploads: Int = 0

  // MARK: - Body

  var body: some View {
    ScrollView {
      VStack {
        // Display the current session settings.
        Text("Aktuelle Einstellung:")
          .font(.footnote)
        Text(
          "S: \(String(format: "%.1f", current_setting.learn)), P: \(Int(current_setting.pause)), A: \(Int(current_setting.repetitions))"
        )
        .font(.footnote)
        .scenePadding()

        // Show "Change Settings" button only when the session is not active.
        if !WritingExerciseManager.showRunView {
          Button(action: {
            showPickerSheet = true
          }) {
            Text("Einstellung ändern")
              .font(.footnote)
          }
          .padding()
        }

        // Show "Stop Exercise" button only when the session is active.
        if WritingExerciseManager.showRunView {
          Button("Übung stoppen") {
            WritingExerciseManager.showRunView = false
            WritingExerciseManager.stopExercise {
              WritingExerciseManager.resetExercise()
            }
          }
          .padding()
        }

        // Toggles for session mode and feedback type.
        Toggle(isOn: $WritingExerciseManager.pomodoro) {
          Text("Pomodoro")
        }
        .padding()

        Toggle(isOn: $WritingExerciseManager.positive_feedback) {
          Text(
            WritingExerciseManager.positive_feedback
              ? "Positive Feedback is on" : "Negative Feedback is on")
        }
        .padding()

        // Informational text about the settings.
        VStack(alignment: .leading) {
          Divider()
            .frame(width: 5)
            .background(Color.blue)
          Text(
            """
            Passe deine Fokus-Routine an:

            Du kannst die Dauer deiner Schreibzeit (S) festlegen.

            Aktiviere den "Pomodoro"-Modus, um deine Übungen in Arbeitsphase (A) mit Pausen (P) zu unterteilen, oder arbeite ohne Unterbrechungen.

            Wähle positives oder negatives haptisches Feedback.
            """
          )
          .font(.footnote)
          .foregroundColor(.blue)
          .padding()
        }

        // Button to reset settings to their default/remote state.
        if !WritingExerciseManager.showRunView {
          Button(action: {
            configs.resetConfigs()
          }) {
            Text("Einstellung zurücksetzen")
              .font(.footnote)
          }
          .padding()
        }

        // Section for handling failed data uploads.
        let check_if_anyfaileduploads = !failedUploads.isEmpty
        let number_of_failed_uploads = failedUploads.count

        if check_if_anyfaileduploads {
          if isLoading {
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle())
              .padding()
          } else {
            Button(action: {
              isLoading = true
              DispatchQueue.global(qos: .userInitiated).async {
                dbManager.tryUploads { result in
                  DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                      // Refresh the list of failed uploads after a successful retry.
                      self.failedUploads = dbManager.getFailedUploads()
                    case .failure(let error):
                      print("Retry failed with error: \(error.localizedDescription)")
                    }
                    isLoading = false
                  }
                }
              }
            }) {
              Text("Upload data \(number_of_failed_uploads)")
                .font(.footnote)
                .padding()
            }
            .padding()
          }

          // Display the list of files that failed to upload.
          Text("Failed Uploads:\n\(sortedFailedUploadsText)")
            .font(.footnote)
            .padding()
        }

        // Section for cleaning up orphaned files if storage is low.
        if lowStorage {
          Button(action: {
            dbManager.tryUploads { _ in
              // dbManager.cleanOrphanedFiles() // This action can be enabled if needed.
            }
          }) {
            Text("Delete orphaned Files")
              .font(.footnote)
              .padding()
          }
        }

        // Display the device ID prefix.
        Text("ID: " + String(deviceUUIDPrefix))
          .font(.footnote)
          .scenePadding()
      }
      .padding()
    }
    .sheet(isPresented: $showPickerSheet) {
      // Present the picker view as a sheet to modify settings.
      PickerSheetView(
        learnValue: $learnValue,
        pauseValue: $pauseValue,
        repetitionsValue: $repetitionsValue,
        current_setting: $current_setting,
        saveCurrentConfig: saveCurrentConfig
      )
    }
    .onAppear {
      // Initialize state variables when the view appears.
      learnValue = Int(current_setting.learn)
      pauseValue = Int(current_setting.pause)
      repetitionsValue = current_setting.repetitions
      failedUploads = dbManager.getFailedUploads()
      checkAvailableStorage()
      loadAvailableFiles()
    }
  }

  // MARK: - Helper Methods

  /// Saves the current configuration to UserDefaults.
  private func saveCurrentConfig() {
    configs.storeConfigInUserDefaults(config: current_setting, forKey: "config_\(deviceUUIDPrefix)")
  }

  /// Checks the available disk space and updates the `lowStorage` flag.
  private func checkAvailableStorage() {
    let freeSpace = getAvailableStorageSpace()
    let minimumFreeSpace: Int64 = 2 * (1024 * 1024 * 1024)  // 2 GB
    self.lowStorage = freeSpace < minimumFreeSpace
  }

  /// Gets the available free storage space on the device.
  /// - Returns: The free space in bytes.
  private func getAvailableStorageSpace() -> Int64 {
    if let attributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
      let freeSize = attributes[.systemFreeSize] as? Int64
    {
      return freeSize
    }
    return 0
  }

  /// Loads the list of locally stored .bin and .json files.
  private func loadAvailableFiles() {
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
      .first!
    let allFiles = try? FileManager.default.contentsOfDirectory(
      at: documentsDirectory, includingPropertiesForKeys: nil)
    availableFiles =
      allFiles?.filter { $0.pathExtension == "bin" || $0.pathExtension == "json" } ?? []
  }

  /// A computed property that returns a formatted and sorted string of failed upload filenames.
  private var sortedFailedUploadsText: String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
    dateFormatter.timeZone = TimeZone(identifier: "Europe/Zurich")

    // Map failed uploads to a tuple containing a display name and date for sorting.
    let uploadsWithDates: [(displayName: String, date: Date)] = failedUploads.compactMap { upload in
      guard let fileURL = URL(string: upload.fileURLString) else { return nil }
      let filename = fileURL.deletingPathExtension().lastPathComponent

      let components = filename.components(separatedBy: "_")
      guard components.count >= 3 else { return nil }

      let dateString = "\(components[1])_\(components[2])"
      guard let date = dateFormatter.date(from: dateString) else { return nil }

      let displayName = components.dropFirst().joined(separator: "_")
      return (displayName: displayName, date: date)
    }

    // Sort by date, newest first.
    let sortedUploads = uploadsWithDates.sorted { $0.date > $1.date }

    // Join the display names into a single string.
    let failedUploadsText = sortedUploads.map { "\($0.displayName)" }.joined(separator: "\n")
    return failedUploadsText
  }
}

// MARK: - PickerSheetView
/// A view presented as a sheet, containing pickers to adjust the session configuration.
struct PickerSheetView: View {
  // MARK: - Properties

  @EnvironmentObject var WritingExerciseManager: WritingExerciseManager
  @Binding var learnValue: Int
  @Binding var pauseValue: Int
  @Binding var repetitionsValue: Int
  @Binding var current_setting: Config

  /// A closure that is called to save the configuration.
  var saveCurrentConfig: () -> Void

  // MARK: - Body

  var body: some View {
    ScrollView {
      VStack {
        PickerSectionView(title: "Schreiben", value: $learnValue, range: 1..<50) {
          current_setting.learn = Double(learnValue)
          saveCurrentConfig()
        }
        // Show pause and repetition pickers only if Pomodoro mode is enabled.
        if WritingExerciseManager.pomodoro {
          PickerSectionView(title: "Pause", value: $pauseValue, range: 1..<30) {
            current_setting.pause = Double(pauseValue)
            saveCurrentConfig()
          }
          PickerSectionView(title: "Arbeitsphasen", value: $repetitionsValue, range: 1..<10) {
            current_setting.repetitions = repetitionsValue
            saveCurrentConfig()
          }
        }
      }
      .padding()
    }
  }
}

// MARK: - PickerSectionView
/// A reusable view component for a single picker with a title.
struct PickerSectionView: View {
  // MARK: - Properties

  var title: String
  @Binding var value: Int
  var range: Range<Int>
  var onChange: () -> Void

  // MARK: - Body

  var body: some View {
    VStack {
      Text(title)
        .font(.headline)
      Picker(title, selection: $value) {
        ForEach(range, id: \.self) { value in
          Text("\(value)").tag(value)
        }
      }
      .pickerStyle(WheelPickerStyle())
      .frame(width: 70, height: 70)
      .onChange(of: value) {
        // Perform the save action whenever the picker value changes.
        onChange()
      }
    }
    .padding()
  }
}

// MARK: - FileUploadView
/// A view for manually selecting and uploading or restoring local data files.
struct FileUploadView: View {
  // MARK: - Properties

  @State private var availableFiles: [URL] = []
  @State private var selectedFile: URL?
  @State private var isLoading = false
  @State private var alertTitle = ""
  @State private var alertMessage = ""
  @State private var showAlert = false

  let dbManager = DataStorageManager()

  /// A computed property that sorts the available files by date, newest first.
  var sortedAvailableFiles: [URL] {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
    dateFormatter.timeZone = TimeZone(identifier: "Europe/Zurich")

    return availableFiles.compactMap { fileURL -> (url: URL, date: Date)? in
      let fileName = fileURL.deletingPathExtension().lastPathComponent
      let components = fileName.components(separatedBy: "_")
      guard components.count >= 3 else { return nil }

      let dateString = "\(components[1])_\(components[2])"
      guard let date = dateFormatter.date(from: dateString) else { return nil }

      return (url: fileURL, date: date)
    }
    .sorted { $0.date > $1.date }
    .map { $0.url }
  }

  // MARK: - Body

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // List of available local files.
      List(sortedAvailableFiles, id: \.self) { file in
        let fileName = file.deletingPathExtension().lastPathComponent
        let displayName =
          fileName.components(separatedBy: "_").dropFirst().joined(separator: "_") + "."
          + file.pathExtension

        HStack {
          Text(displayName)
            .font(.footnote)
          Spacer()
          if file == selectedFile {
            Image(systemName: "checkmark")
              .foregroundColor(.blue)
          }
        }
        .contentShape(Rectangle())
        .onTapGesture {
          selectedFile = file
          print("Selected file: \(displayName)")
        }
      }
      .listStyle(.plain)
      .frame(maxHeight: .infinity)
      .padding(.horizontal)

      // Action buttons for the selected file.
      if let selectedFile = selectedFile {
        HStack(spacing: 16) {
          Button(action: {
            uploadFile(selectedFile)
          }) {
            Text("Upload")
              .font(.footnote)
              .foregroundColor(.white)
              .padding(.vertical, 6)
              .padding(.horizontal, 12)
              .background(Color.blue)
              .cornerRadius(8)
          }
          .buttonStyle(PlainButtonStyle())
          .disabled(isLoading)

          Button(action: {
            // This button re-creates a .bin file from a .json file's date range.
            let sessionFilename = selectedFile.lastPathComponent
            dbManager.fetchAndStoreAccelerometerData(sessionFilename: sessionFilename) { result in
              switch result {
              case .success(let url):
                print("Successfully restored bin file: \(url.lastPathComponent)")
                alertTitle = "Restoration Completed"
                alertMessage = "Bin file restored successfully for \(sessionFilename)."
              case .failure(let error):
                print("Failed to restore bin file: \(error.localizedDescription)")
                alertTitle = "Restoration Failed"
                alertMessage =
                  "Failed to restore bin file for \(sessionFilename): \(error.localizedDescription)"
              }
              showAlert = true
            }
          }) {
            Text("Restore")
              .font(.footnote)
              .foregroundColor(.white)
              .padding(.vertical, 6)
              .padding(.horizontal, 12)
              .background(Color.green)
              .cornerRadius(8)
          }
          .buttonStyle(PlainButtonStyle())
          .disabled(isLoading || selectedFile.pathExtension.lowercased() != "json")  // Enable only for JSON files.
        }
        .padding(.horizontal)
      }
    }
    .onAppear(perform: loadAvailableFiles)
    .alert(isPresented: $showAlert) {
      Alert(
        title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
    }
  }

  // MARK: - Helper Methods

  /// Loads the list of files from the documents directory.
  private func loadAvailableFiles() {
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
      .first!
    if let allFiles = try? FileManager.default.contentsOfDirectory(
      at: documentsDirectory, includingPropertiesForKeys: nil)
    {
      availableFiles = allFiles.filter { $0.pathExtension == "bin" || $0.pathExtension == "json" }
      print("Loaded files: \(availableFiles.map { $0.lastPathComponent })")
    } else {
      print("No files found in documents directory.")
    }
  }

  /// Initiates the upload process for a given file URL.
  private func uploadFile(_ fileURL: URL) {
    isLoading = true
    do {
      let data = try Data(contentsOf: fileURL)
      let filename = fileURL.lastPathComponent
      let fileExtension = fileURL.pathExtension.lowercased()

      // Upload to the correct Google Drive folder based on file type.
      switch fileExtension {
      case "bin":
        dbManager.uploadToGoogleDrive(
          data: data, filename: filename, folderID: GoogleDB.data_folder
        ) { result in
          handleUploadResult(result, filename: filename)
        }
      case "json":
        dbManager.uploadToGoogleDrive(
          data: data, filename: filename, folderID: GoogleDB.config_log_folder
        ) { result in
          handleUploadResult(result, filename: filename)
        }
      default:
        print("Unsupported file type: \(filename)")
        isLoading = false
      }
    } catch {
      print("Failed to read data for upload: \(error.localizedDescription)")
      isLoading = false
    }
  }

  /// Handles the result of an upload attempt and displays an alert.
  private func handleUploadResult(_ result: Result<Void, Error>, filename: String) {
    DispatchQueue.main.async {
      isLoading = false
      switch result {
      case .success:
        alertTitle = "Upload Completed"
        alertMessage = "\(filename) uploaded successfully."
      case .failure(let error):
        alertTitle = "Upload Failed"
        alertMessage = "Failed to upload \(filename): \(error.localizedDescription)"
      }
      showAlert = true
    }
  }

  /// Deletes specific temporary or corrupted files from the documents directory.
  func deleteSpecificFiles() {
    let fileManager = FileManager.default
    let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!

    do {
      let allFiles = try fileManager.contentsOfDirectory(atPath: documentsDirectory.path)

      for file in allFiles {
        // Define criteria for files to be deleted.
        if file.hasPrefix("failed_upload") || file.hasSuffix(".bin.bin")
          || file.hasSuffix(".json.bin")
        {
          let fileURL = documentsDirectory.appendingPathComponent(file)

          do {
            try fileManager.removeItem(at: fileURL)
            print("Deleted file: \(file)")
          } catch {
            print("Failed to delete file: \(file), error: \(error)")
          }
        }
      }
    } catch {
      print("Failed to list files in directory: \(documentsDirectory.path), error: \(error)")
    }
  }
}

#Preview {
  WritingConfigurationsView(current_setting: .constant(UserConfigs.shared.configs))
    .environmentObject(WritingExerciseManager())
}
