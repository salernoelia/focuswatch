import SwiftUI
import AVFoundation
import Combine

struct AnneView: View {
    //@ObservedObject var recorder: AudioRecorder
    @State private var currentFrame = 1
    @StateObject private var recorder = AudioRecorder()
    private let frameCount = 5
    private let frameDuration: TimeInterval = 0.2

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
