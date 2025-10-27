//
//  WritingTimeManager.swift
//  FokusUhr Watch App
//
//  Created by Julian Amacker on 08.02.2024.
//
import Foundation

/// TODO: RENAME
class WritingTimeManager: ObservableObject {
  /// - Returns: The time in seconds
  /// - Parameter timerTime: The time in seconds
  private var timerTime: Int
  /// The time in minutes
  private var timer: Timer?
  /// The timer
  private var countDown: Bool
  /// The timer direction
  @Published var currentTime: Int
  /// the current time in seconds

  init(time: Double, countDown: Bool = true) {
    self.timerTime = Int(time * 60)  // Convert minutes to seconds
    self.currentTime = timerTime
    self.countDown = countDown
  }

  func startTimer() {
    // Invalidate the existing timer if it exists
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
