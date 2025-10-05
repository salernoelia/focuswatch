import Foundation
import AVFoundation
import Combine

class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var errorMessage: String?
    @Published var isUploading = false
    @Published var uploadStatus: String?
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingURL: URL?
    
    private let serverURL = "http://192.168.1.137:8080/upload"
    
    func startRecording() {
        Task {
            let granted: Bool
            if #available(watchOS 10.0, *) {
                granted = await PermissionManager.requestAudioPermission()
            } else {
                granted = await PermissionManager.requestAudioPermissionLegacy()
            }
            
            await MainActor.run {
                if granted {
                    setupRecordingSession()
                } else {
                    errorMessage = AppError.microphoneAccessDenied.errorDescription
                }
            }
        }
    }
    
    private func setupRecordingSession() {
        do {
            try AudioSessionManager.setupRecordingSession()
            let fileURL = try FileManager.default.recordingFileURL()
            try FileManager.default.removeFileIfExists(at: fileURL)
            
            let settings = AudioSessionManager.createRecordingSettings()
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.prepareToRecord()
            
            guard audioRecorder?.record() == true else {
                errorMessage = AppError.recordingFailed(reason: "Failed to start recording").errorDescription
                return
            }
            
            recordingURL = fileURL
            isRecording = true
            errorMessage = nil
            uploadStatus = nil
        } catch let error as AppError {
            errorMessage = error.errorDescription
            #if DEBUG
            ErrorLogger.log(error)
            #endif
        } catch {
            let appError = AppError.audioSessionError(underlying: error)
            errorMessage = appError.errorDescription
            #if DEBUG
            ErrorLogger.log(appError)
            #endif
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        
        do {
            try AudioSessionManager.deactivateSession()
        } catch {
            let appError = AppError.audioSessionError(underlying: error)
            #if DEBUG
            ErrorLogger.log(appError)
            #endif
        }
    }
    
    func replayRecording() {
        guard let url = recordingURL else {
            errorMessage = AppError.playbackFailed(reason: "No recording to play").errorDescription
            return
        }
        
        do {
            try AudioSessionManager.setupPlaybackSession()
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            
            guard audioPlayer?.play() == true else {
                errorMessage = AppError.playbackFailed(reason: "Failed to play recording").errorDescription
                return
            }
            
            errorMessage = nil
        } catch {
            let appError = AppError.playbackFailed(reason: error.localizedDescription)
            errorMessage = appError.errorDescription
            #if DEBUG
            ErrorLogger.log(appError)
            #endif
        }
    }
    
    
    func uploadRecording() {
        guard let url = recordingURL else {
            errorMessage = AppError.fileNotFound(path: "recording").errorDescription
            return
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            let appError = AppError.fileNotFound(path: url.path)
            errorMessage = appError.errorDescription
            #if DEBUG
            ErrorLogger.log(appError)
            #endif
            return
        }
        
        Task {
            await performUpload(from: url)
        }
    }
    
    private func performUpload(from url: URL) async {
        await MainActor.run {
            isUploading = true
            uploadStatus = "Uploading..."
        }
        
        do {
            let audioData = try Data(contentsOf: url)
            
            guard let uploadURL = URL(string: serverURL) else {
                throw AppError.invalidData(reason: "Invalid server URL")
            }
            
            var request = URLRequest(url: uploadURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let filename = "watch_recording_\(Date().timeIntervalSince1970).m4a"
            let payload: [String: Any] = [
                "filename": filename,
                "audioData": audioData.base64EncodedString()
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError.invalidResponse
            }
            
            await MainActor.run {
                isUploading = false
                
                if (200...299).contains(httpResponse.statusCode) {
                    uploadStatus = "Upload successful!"
                } else {
                    let responseMessage = String(data: data, encoding: .utf8) ?? "No data"
                    uploadStatus = AppError.requestFailed(statusCode: httpResponse.statusCode, message: responseMessage).errorDescription
                }
            }
        } catch let error as AppError {
            await MainActor.run {
                isUploading = false
                uploadStatus = error.errorDescription
            }
            #if DEBUG
            ErrorLogger.log(error)
            #endif
        } catch {
            let appError = AppError.fileOperationFailed(operation: "upload recording", underlying: error)
            await MainActor.run {
                isUploading = false
                uploadStatus = appError.errorDescription
            }
            #if DEBUG
            ErrorLogger.log(appError)
            #endif
        }
    }
}

extension AudioRecorder: AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            errorMessage = AppError.recordingFailed(reason: "Recording did not complete successfully").errorDescription
        }
        isRecording = false
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if !flag {
            errorMessage = AppError.playbackFailed(reason: "Playback did not complete successfully").errorDescription
        }
    }
}
