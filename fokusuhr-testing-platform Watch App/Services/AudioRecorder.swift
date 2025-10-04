import Foundation
import AVFoundation
import Combine


class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var errorMessage: String?
    @Published var isUploading = false
    @Published var uploadStatus: String?
    
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    var recordingURL: URL?
    
    // TODO: Configure server URL after setup of anne endpoint
    private var serverURL: String {
        return "http://192.168.1.137:8080/upload" // dead fallback
    }
    
    func startRecording() {
        if #available(watchOS 10.0, *) {
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                guard let self = self else { return }
                
                if granted {
                    DispatchQueue.main.async {
                        self.setupRecordingSession()
                    }
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = AppError.microphoneAccessDenied.errorDescription
                    }
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                guard let self = self else { return }
                
                if granted {
                    DispatchQueue.main.async {
                        self.setupRecordingSession()
                    }
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = AppError.microphoneAccessDenied.errorDescription
                    }
                }
            }
        }
    }
    
    private func setupRecordingSession() {
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            
            guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                errorMessage = AppError.fileNotFound(path: "documents directory").errorDescription
                return
            }
            
            let fileURL = documentsURL.appendingPathComponent(AppConstants.Audio.recordingFileName)
            
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: AppConstants.Audio.sampleRate,
                AVNumberOfChannelsKey: AppConstants.Audio.numberOfChannels,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
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
            try AVAudioSession.sharedInstance().setActive(false)
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
        
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            
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
        
        isUploading = true
        uploadStatus = "Uploading..."
        
        #if DEBUG
        print("Attempting to upload recording from URL: \(url)")
        #endif

        do {
            let audioData = try Data(contentsOf: url)
            
            #if DEBUG
            print("Audio data read successfully. Size: \(audioData.count) bytes")
            #endif

            guard let uploadURL = URL(string: serverURL) else {
                let appError = AppError.invalidData(reason: "Invalid server URL: \(serverURL)")
                errorMessage = appError.errorDescription
                #if DEBUG
                ErrorLogger.log(appError)
                #endif
                isUploading = false
                return
            }
            
            var request = URLRequest(url: uploadURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let filename = "watch_recording_\(Date().timeIntervalSince1970).m4a"
            let payload: [String: Any] = [
                "filename": filename,
                "audioData": audioData.base64EncodedString()
            ]
            
            let jsonData = try JSONSerialization.data(withJSONObject: payload)
            request.httpBody = jsonData
            
            let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                DispatchQueue.main.async {
                    self?.isUploading = false

                    if let error = error {
                        let appError = AppError.serverError(underlying: error)
                        self?.uploadStatus = appError.errorDescription
                        #if DEBUG
                        ErrorLogger.log(appError)
                        #endif
                        return
                    }

                    guard let httpResponse = response as? HTTPURLResponse else {
                        let appError = AppError.invalidResponse
                        self?.uploadStatus = appError.errorDescription
                        #if DEBUG
                        ErrorLogger.log(appError)
                        #endif
                        return
                    }

                    if (200...299).contains(httpResponse.statusCode) {
                        self?.uploadStatus = "Upload successful!"
                        #if DEBUG
                        print("Upload successful! HTTP Status: \(httpResponse.statusCode)")
                        #endif
                    } else {
                        let responseData = data.flatMap { String(data: $0, encoding: .utf8) } ?? "No data"
                        let appError = AppError.requestFailed(statusCode: httpResponse.statusCode, message: responseData)
                        self?.uploadStatus = appError.errorDescription
                        #if DEBUG
                        ErrorLogger.log(appError)
                        #endif
                    }
                }
            }
            task.resume()

        } catch {
            isUploading = false
            let appError = AppError.fileOperationFailed(operation: "upload recording", underlying: error)
            uploadStatus = appError.errorDescription
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
