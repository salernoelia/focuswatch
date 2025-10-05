import SwiftUI
import AVFoundation
import Combine

struct AnneView: View {

    @State private var currentFrame = 1
    @StateObject private var recorder = AudioRecorder()
    private let frameCount = 5
    private let frameDuration: TimeInterval = 0.2
    
    private let appLogger = AppLogger.shared

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
                Task {
                    await appLogger.logSimpleEvent(appName: "anne", eventType: "button_clicked")
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
    }

    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: frameDuration, repeats: true) { timer in
            currentFrame = (currentFrame % frameCount) + 1
        }
    }
}
