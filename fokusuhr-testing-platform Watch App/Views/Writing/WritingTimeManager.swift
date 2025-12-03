import Foundation

class WritingTimeManager: ObservableObject {
  private var timerTime: Int
  private var timer: Timer?
  private var countDown: Bool
  @Published var currentTime: Int

  init(time: Double, countDown: Bool = true) {
    self.timerTime = Int(time * 60)
    self.currentTime = timerTime
    self.countDown = countDown
  }

  func startTimer() {
    timer?.invalidate()

    self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      DispatchQueue.main.async {  // possibly redundant
        self?.updateTimer()
      }
    }
  }

  func stopTimer() {
    timer?.invalidate()
    //timer = nil
  }

  private func updateTimer() {
    if countDown {
      if currentTime > 0 {
        currentTime -= 1
      } else {
        timer?.invalidate()
      }
    } else {
      currentTime += 1
    }
  }

  func resumeTimer() {
    startTimer()
  }
}
