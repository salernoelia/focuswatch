//
//  ColorBreathingViewModel.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 27.10.2025.
//


import SwiftUI
import WatchKit

class ColorBreathingViewModel: ObservableObject {
  @Published var scale: CGFloat = 0.5
  @Published var isInhaling: Bool = true

  private var timer: Timer?

  func startBreathing() {
    scale = 1.2
    timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
      guard let self = self else { return }
      self.isInhaling.toggle()
      self.vibrate()
    }
  }

  func stopBreathing() {
    timer?.invalidate()
    timer = nil
  }

  private func vibrate() {
    WKInterfaceDevice.current().play(.notification)
  }
}
