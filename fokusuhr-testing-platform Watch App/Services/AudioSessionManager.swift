import Foundation
import AVFoundation

enum AudioSessionManager {
    
    static func setupRecordingSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default)
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    static func setupPlaybackSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)
    }
    
    static func deactivateSession() throws {
        try AVAudioSession.sharedInstance().setActive(false)
    }
    
    static func createRecordingSettings() -> [String: Any] {
        [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: AppConstants.Audio.sampleRate,
            AVNumberOfChannelsKey: AppConstants.Audio.numberOfChannels,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
    }
}
