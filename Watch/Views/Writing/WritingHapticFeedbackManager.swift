//
//  WritingHapticFeedbackManager.swift
//  FokusUhr Watch App
//
//  Created by Julian Amacker on 03.11.2024.
//

import Combine
import CoreMotion
import Foundation
import SwiftUI
import WidgetKit

class WritingHapticFeedbackManager: ObservableObject {
  private var timer: DispatchSourceTimer?
  private let device = WKInterfaceDevice.current()
  private weak var WritingExerciseManager: WritingExerciseManager?
  var isHapticFeedbackActive: Bool {
    return timer != nil
  }

  init(WritingExerciseManager: WritingExerciseManager) {
    self.WritingExerciseManager = WritingExerciseManager
  }

  func playHaptic(type: WKHapticType, repeatCount: Int = 1, delayBetween: TimeInterval = 0.5) {
    guard UserConfigs.shared.configs.feedbackEnabled else { return }

    let hapticFeedbackType = self.mapHapticTypeToFeedbackType(type: type)

    self.WritingExerciseManager?.logStateChange(hapticFeedbackType: hapticFeedbackType)

    for i in 0..<repeatCount {
      let delay = TimeInterval(i) * delayBetween
      DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
        guard let self = self else { return }
        self.device.play(type)
        print("Played haptic \(type) at \(Date())")
      }
    }
  }

  func startHapticFeedback(interval: TimeInterval) {
    guard UserConfigs.shared.configs.feedbackEnabled == true else { return }

    stopHapticFeedback()

    let timer = DispatchSource.makeTimerSource()
    timer.schedule(deadline: .now(), repeating: interval)
    timer.setEventHandler { [weak self] in
      DispatchQueue.main.async {
        self?.device.play(.failure)
        self?.WritingExerciseManager?.logStateChange(hapticFeedbackType: .negFB)
      }
    }

    self.timer = timer
    timer.resume()
  }

  func stopHapticFeedback() {
    guard let timer = timer else { return }
    print("Haptic feedback stopped at \(Date())")
    timer.cancel()
    self.timer = nil
  }

  private func mapHapticTypeToFeedbackType(type: WKHapticType)
    -> WritingExerciseManager.ExerciseState
  {
    switch type {
    case .start:
      return .startFB
    case .stop:
      return .endFB
    case .notification:
      return .pauseFB
    case .success:
      return .posFB
    case .failure:
      return .negFB
    default:
      return .startFB
    }
  }
}
