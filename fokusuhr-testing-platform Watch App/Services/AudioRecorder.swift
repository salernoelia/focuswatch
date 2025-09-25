//
//  AudioRecorder.swift
//  wear-apple-watch Watch App
//
//  Created by Elia Salerno on 01.03.2025.
//

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
    
    private let serverURL = "http://192.168.1.137:8080/upload"
    
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
                        self.errorMessage = "Microphone access denied"
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
                        self.errorMessage = "Microphone access denied"
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
            
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = docs.appendingPathComponent("recording.m4a")
            

            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.prepareToRecord()
            
            if audioRecorder?.record() == true {
                recordingURL = fileURL
                isRecording = true
                errorMessage = nil
                uploadStatus = nil
            } else {
                errorMessage = "Failed to start recording"
            }
        } catch {
            errorMessage = "Recording setup error: \(error.localizedDescription)"
            print("Error starting recording:", error)
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Error deactivating audio session:", error)
        }
    }
    
    func replayRecording() {
        guard let url = recordingURL else {
            errorMessage = "No recording to play"
            return
        }
        
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            
            if audioPlayer?.play() == true {
                errorMessage = nil
            } else {
                errorMessage = "Failed to play recording"
            }
        } catch {
            errorMessage = "Playback error: \(error.localizedDescription)"
            print("Error playing recording:", error)
        }
    }
    
    
    func uploadRecording() {
        guard let url = recordingURL else {
            errorMessage = "No recording to upload"
            return
        }


        if !FileManager.default.fileExists(atPath: url.path) {
            errorMessage = "Recording file not found at: \(url.path)"
            print("Error: Recording file not found at: \(url.path)")
            return
        }
        
        isUploading = true
        uploadStatus = "Uploading..."
        print("Attempting to upload recording from URL: \(url)")

        do {

            let audioData = try Data(contentsOf: url)
            print("Audio data read successfully. Size: \(audioData.count) bytes")


            guard let uploadURL = URL(string: serverURL) else {
                errorMessage = "Invalid server URL: \(serverURL)"
                print("Error: Invalid server URL: \(serverURL)")
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
                        self?.uploadStatus = "Upload failed: \(error.localizedDescription)"
                        print("Upload failed with error: \(error.localizedDescription)")
                        return
                    }

                    guard let httpResponse = response as? HTTPURLResponse else {
                        self?.uploadStatus = "Invalid response"
                        print("Upload failed: Invalid response")
                        return
                    }

                    if (200...299).contains(httpResponse.statusCode) {
                        self?.uploadStatus = "Upload successful!"
                        print("Upload successful! HTTP Status: \(httpResponse.statusCode)")
                    } else {
                        let responseData = data != nil ? String(data: data!, encoding: .utf8) : "No data"
                        self?.uploadStatus = "Upload failed (HTTP \(httpResponse.statusCode)): \(responseData ?? "")"
                        print("Upload failed (HTTP \(httpResponse.statusCode)): \(responseData ?? "")")
                    }
                }
            }
            task.resume()

        } catch {
            isUploading = false
            uploadStatus = "Upload preparation failed: \(error.localizedDescription)"
            print("Upload preparation failed: \(error.localizedDescription)")
        }

    }
}

extension AudioRecorder: AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            errorMessage = "Recording failed to complete successfully"
        }
        isRecording = false
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if !flag {
            errorMessage = "Playback failed to complete successfully"
        }
    }
}
