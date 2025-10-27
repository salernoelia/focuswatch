import Foundation
import WatchKit

class VibrationManager: ObservableObject {
  static let shared = VibrationManager()

  private var lastVibrationTime: TimeInterval = 0
  private var vibrationFrameCounter: Int = 0
  private let device = WKInterfaceDevice.current()
  private var pomodoroVibrationTimer: DispatchSourceTimer?
  func startPomodoroRandomVibrations(intervalRange: ClosedRange<Int>, intensity: WKHapticType) {
    stopPomodoroRandomVibrations()
    let timer = DispatchSource.makeTimerSource()
    scheduleNextRandomVibration(timer: timer, intervalRange: intervalRange, intensity: intensity)
    pomodoroVibrationTimer = timer
    timer.resume()
  }

  private func scheduleNextRandomVibration(
    timer: DispatchSourceTimer, intervalRange: ClosedRange<Int>, intensity: WKHapticType
  ) {
    let randomInterval = Int.random(in: intervalRange)
    timer.schedule(deadline: .now() + .seconds(randomInterval))
    timer.setEventHandler { [weak self] in
      DispatchQueue.main.async {
        self?.device.play(intensity)
        if let strongSelf = self {
          strongSelf.scheduleNextRandomVibration(
            timer: timer, intervalRange: intervalRange, intensity: intensity)
        }
      }
    }
  }

  func stopPomodoroRandomVibrations() {
    pomodoroVibrationTimer?.cancel()
    pomodoroVibrationTimer = nil
  }

  private init() {}

  func playHaptic(_ type: WKHapticType) {
    device.play(type)
  }

  func lightVibration() {
    device.play(.click)
  }

  func mediumVibration() {
    device.play(.start)
  }

  func strongVibration() {
    device.play(.notification)
  }

  func customVibration(_ type: WKHapticType) {
    device.play(type)
  }

  func triggerVelocityVibration(velocity: Double) {
    let currentTime = Date().timeIntervalSince1970
    let normalizedVelocity = min(abs(velocity), 100)

    let minInterval: TimeInterval = 0.02
    let maxInterval: TimeInterval = 0.1
    let velocityFactor = normalizedVelocity / 100
    let targetInterval = maxInterval - (velocityFactor * (maxInterval - minInterval))

    guard currentTime - lastVibrationTime >= targetInterval else { return }

    lastVibrationTime = currentTime

    vibrationFrameCounter += 1
    let frameSkip = max(1, Int(4 - (velocityFactor * 3)))

    guard vibrationFrameCounter % frameSkip == 0 else { return }

    let intensity = normalizedVelocity / 100

    switch intensity {
    case 0.0..<0.2:
      device.play(.click)
    case 0.2..<0.5:
      device.play(.start)
    case 0.5..<0.8:
      device.play(.stop)
    default:
      device.play(.retry)
    }
  }

  func resetVibrationTiming() {
    lastVibrationTime = 0
    vibrationFrameCounter = 0
  }
}
