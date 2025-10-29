import SwiftUI
import AVFoundation
import Combine

struct AnneView: View {

    @State private var currentFrame = 1
    @StateObject private var recorder = AudioRecorder()
    private let frameCount = 5
    private let frameDuration: TimeInterval = 0.2
    
    private let appLogger = AppLogger.shared
    private let telemetryManager = TelemetryManager.shared

    var body: some View {
        VStack(spacing: 12) {
            if let errorMessage = recorder.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            

            Button(recorder.isRecording ? "Stop" : "Sprich zu Anne") {
                if telemetryManager.hasConsent {
                    Task {
                        await appLogger.logSimpleEvent(appName: "anne", eventType: "voice_recording_triggered")
                    }
                }
              
                
                if recorder.isRecording {
                    recorder.uploadRecording()
                    recorder.stopRecording()
                } else {
                    recorder.startRecording()
                }
            }
            .foregroundColor(recorder.isRecording ? .red : .blue)
            .buttonStyle(.bordered)
        }
        .onAppear {
            appLogger.logViewLifecycle(appName: "anne", event: "open")
        }
        .onDisappear {
            appLogger.logViewLifecycle(appName: "anne", event: "closed")
        }
    }

    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: frameDuration, repeats: true) { timer in
            currentFrame = (currentFrame % frameCount) + 1
        }
    }
}
