import Combine
import SwiftUI

class FidgetToyViewModel: ObservableObject {
  @Published var position: CGSize = .zero
  @Published var isMoving: Bool = false
  private var feedbackTimer: Timer?

  func startVibration() {
    guard feedbackTimer == nil else { return }
    feedbackTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
      WKInterfaceDevice.current().play(.directionUp)  // .directionDown .success .click
    }
  }

  func stopVibration() {
    feedbackTimer?.invalidate()
    feedbackTimer = nil
  }

  func updatePosition(_ value: DragGesture.Value) {
    position = value.translation
    isMoving = true
    startVibration()
  }

  func endDrag() {
    isMoving = false
    position = .zero
    stopVibration()
  }
}
