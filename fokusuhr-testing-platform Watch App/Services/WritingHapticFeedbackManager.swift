//
//  HapticFeedbackManager.swift
//  FokusUhr Watch App
//
//  Created by Julian Amacker on 03.11.2024.
//

import Foundation
import Foundation
import CoreMotion
import SwiftUI
import Combine
import WidgetKit

class HapticFeedbackManager: ObservableObject {
    private var timer: DispatchSourceTimer?
    private let device = WKInterfaceDevice.current()
    private weak var exerciseManager: ExerciseManager?
    var isHapticFeedbackActive: Bool {
        return timer != nil
    }

    // Initialize with an ExerciseManager reference
    init(exerciseManager: ExerciseManager) {
        self.exerciseManager = exerciseManager
    }
    
    // General method to play haptic feedback
    func playHaptic(type: WKHapticType, repeatCount: Int = 1, delayBetween: TimeInterval = 0.5) {
        guard UserConfigs.shared.configs.feedbackEnabled else { return }

        // Calculate hapticFeedbackType once before the loop
        let hapticFeedbackType = self.mapHapticTypeToFeedbackType(type: type)
        
        // Log the state change once
        self.exerciseManager?.logStateChange(hapticFeedbackType: hapticFeedbackType)

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

        stopHapticFeedback()  // Ensure any existing timer is stopped and nil

        let timer = DispatchSource.makeTimerSource()
        timer.schedule(deadline: .now(), repeating: interval)
        timer.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                self?.device.play(.failure)
                self?.exerciseManager?.logStateChange(hapticFeedbackType: .negFB)
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
    
    private func mapHapticTypeToFeedbackType(type: WKHapticType) -> ExerciseManager.ExerciseState {
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
