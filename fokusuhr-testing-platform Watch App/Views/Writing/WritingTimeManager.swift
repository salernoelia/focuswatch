//
//  WritingTimeManager.swift
//  FokusUhr Watch App
//
//  Created by Julian Amacker on 08.02.2024.
//
//  Refactored on 30.01.2025 to use Date-based timing.
//

import Foundation

/// Manages the timer for writing sessions.
/// Uses Date-based calculations to prevent drift and handle background states correctness.
class WritingTimeManager: ObservableObject {
  
  /// The initial duration in seconds (for countdown).
  private var initialDuration: TimeInterval
  
  /// The accumulated time elapsed in previous segments (in seconds).
  private var accumulatedTime: TimeInterval = 0
  
  /// The start time of the current active segment. Nil if paused.
  private var startTime: Date?
  
  /// The timer instance used to trigger UI updates.
  private var timer: Timer?
  
  /// A flag indicating if the timer should count down (true) or up (false).
  private var countDown: Bool
  
  /// The current displayed time in seconds.
  @Published var currentTime: Int
  
  /// Initializes the timer.
  /// - Parameters:
  ///   - time: The duration in minutes.
  ///   - countDown: Whether to count down (default true).
  init(time: Double, countDown: Bool = true) {
    self.initialDuration = time * 60
    self.countDown = countDown
    
    // meaningful initial state
    if countDown {
      self.currentTime = Int(initialDuration)
    } else {
      self.currentTime = 0
    }
  }
  
  /// Starts or resumes the timer.
  func startTimer() {
    // Prevent multiple timers and resetting calls if already running
    guard startTime == nil else { return }
    
    self.startTime = Date()
    
    // Invalidate prior instance just in case
    timer?.invalidate()
    
    // Schedule a timer to update the published `currentTime` property periodically.
    // Logic relies on `startTime`, so the interval here affects UI refresh rate, not accuracy.
    DispatchQueue.main.async { [weak self] in
        self?.timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
  }
  
  /// Stops (pauses) the timer.
  func stopTimer() {
    guard let start = startTime else { return }
    
    // Commit the elapsed time from this segment
    accumulatedTime += Date().timeIntervalSince(start)
    startTime = nil
    
    timer?.invalidate()
    timer = nil
  }
  
  /// Updates the `currentTime` based on elapsed time.
  private func updateTimer() {
    guard let start = startTime else { return }
    
    let currentSegmentElapsed = Date().timeIntervalSince(start)
    let totalElapsed = accumulatedTime + currentSegmentElapsed
    
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      
      if self.countDown {
        let remaining = self.initialDuration - totalElapsed
        if remaining > 0 {
          self.currentTime = Int(ceil(remaining)) // ceil to show "0:01" until fully 0
        } else {
          self.currentTime = 0
          self.stopTimer()
        }
      } else {
        self.currentTime = Int(totalElapsed)
      }
    }
  }
  
  /// Resumes the timer (alias for startTimer).
  func resumeTimer() {
    startTimer()
  }
}
