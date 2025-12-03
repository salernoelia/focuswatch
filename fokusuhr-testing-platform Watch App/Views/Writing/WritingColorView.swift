////
////  AvatarView.swift
////  FokusUhr Watch App
////
////  Created by Julian Amacker on 02.04.2024.

import Foundation
import SwiftUI

struct WritingColorView: View {
  @EnvironmentObject var WritingExerciseManager: WritingExerciseManager
  @State private var showStopConfirmation = false

  var body: some View {
    Group {
      if WritingExerciseManager.showRunView && !UserConfigs.shared.configs.feedbackEnabled {
        Color.black
          .edgesIgnoringSafeArea(.all)
          .onTapGesture {
            showStopConfirmation = true
          }
          .confirmationDialog(
            String(localized: "stop_exercise_title"),
            isPresented: $showStopConfirmation,
            titleVisibility: .visible
          ) {
            Button(String(localized: "stop_exercise_confirm"), role: .destructive) {
              stopExercise()
            }
            Button(String(localized: "Cancel"), role: .cancel) {}
          }
      } else if WritingExerciseManager.showRunView {
        ColorRunView()
      } else {
        StartButton()
      }
    }
  }

  private func stopExercise() {
    WritingExerciseManager.showRunView = false
    WritingExerciseManager.stopExercise {
      WritingExerciseManager.resetExercise()
    }
  }
}

struct StartButton: View {
  @EnvironmentObject var WritingExerciseManager: WritingExerciseManager

  var body: some View {
    GeometryReader { geometry in
      Button(action: {
        WritingExerciseManager.initExtendedSession()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          WritingExerciseManager.showRunView = true
        }
      }) {
        ZStack {
          Circle()
            .fill(Color.green)
            .frame(width: geometry.size.width * 0.8, height: geometry.size.width * 0.8)

          Image(systemName: "pencil.tip.crop.circle.badge.arrow.forward.fill")
            .font(.system(size: geometry.size.width * 0.4))
            .foregroundColor(.white)
        }
        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
      }
      .buttonStyle(PlainButtonStyle())
    }
  }
}

// MARK: - ColorRunView
struct ColorRunView: View {
  @EnvironmentObject var WritingExerciseManager: WritingExerciseManager
  @State private var showStopConfirmation = false
  private var currentSetting = UserConfigs.shared.configs

  /// The state variable that drives the wave animation's phase.
  @State private var wavePhase: CGFloat = 0.0

  // MARK: - Body

  var body: some View {
    GeometryReader { geometry in
      let circleSize = geometry.size.width * 0.8
      let centerX = geometry.size.width / 2
      let centerY = geometry.size.height / 2

      ZStack {
        Color.black.edgesIgnoringSafeArea(.all)

        if WritingExerciseManager.exerciseState != .ended {
          Circle()
            .fill(Color.gray)
            .frame(width: circleSize, height: circleSize)

          Circle()
            .fill(
              LinearGradient(
                gradient: Gradient(colors: [
                  WritingExerciseManager.exerciseState.color,
                  WritingExerciseManager.exerciseState.color.opacity(0.7),
                ]),
                startPoint: .top,
                endPoint: .bottom
              )
            )
            .frame(width: circleSize, height: circleSize)
            .overlay(
              WaveShape(percent: getFillPercentage(), phase: wavePhase)
                .fill(Color.white.opacity(0.8))
                .scaleEffect(x: 1.0, y: -1.0, anchor: .center)
            )
            .mask(Circle())
            .onTapGesture {
              showStopConfirmation = true
            }
        } else {
          Circle()
            .fill(Color.gray)
            .frame(width: circleSize, height: circleSize)

          Circle()
            .fill(
              LinearGradient(
                gradient: Gradient(colors: [Color.purple, Color.purple.opacity(0.7)]),
                startPoint: .top,
                endPoint: .bottom
              )
            )
            .frame(width: circleSize, height: circleSize)

          Image(systemName: "trophy.fill")
            .font(.system(size: 48))
            .foregroundColor(.yellow)
        }
      }
      .position(x: centerX, y: centerY)
      .onAppear {
        withAnimation(Animation.linear(duration: 4.0).repeatForever(autoreverses: false)) {
          wavePhase = .pi * 2
        }
      }
      .confirmationDialog(
        String(localized: "stop_exercise_title"),
        isPresented: $showStopConfirmation,
        titleVisibility: .visible
      ) {
        Button(String(localized: "stop_exercise_confirm"), role: .destructive) {
          stopExercise()
        }
        Button(String(localized: "Cancel"), role: .cancel) {}
      }
    }
  }

  private func stopExercise() {
    WritingExerciseManager.showRunView = false
    WritingExerciseManager.stopExercise {
      WritingExerciseManager.resetExercise()
    }
  }

  // MARK: - Helper Methods

  /// Calculates the fill percentage for the wave shape based on the current time and session mode.
  private func getFillPercentage() -> CGFloat {
    let percentage: Double

    if WritingExerciseManager.exerciseState == .pausing {
      // During pause, the fill level decreases as the pause timer counts down.
      let pauseTimePercentage =
        Double(WritingExerciseManager.currentPauseTime) / Double(currentSetting.pause * 60)
      percentage = 1 - pauseTimePercentage
    } else if WritingExerciseManager.pomodoro {
      // In Pomodoro mode, the fill level increases as the work timer counts down.
      let timePercentage =
        Double(WritingExerciseManager.currentTime) / Double(currentSetting.learn * 60)
      percentage = 1 - timePercentage
    } else {
      // In non-Pomodoro (continuous) mode, the fill level increases based on total accumulated work time.
      let timeWorked = Double(WritingExerciseManager.totalWorkTime())
      let learnTime = Double(currentSetting.learn * 60)
      percentage = (timeWorked / learnTime)
    }

    return CGFloat(percentage)
  }
}

// MARK: - WaveShape
/// A custom, animatable SwiftUI `Shape` that draws a sine wave.
struct WaveShape: Shape {
  // MARK: - Properties

  /// The vertical fill percentage of the shape (0.0 to 1.0).
  var percent: CGFloat
  /// The horizontal phase shift of the sine wave, used for animation.
  var phase: CGFloat

  /// Defines which properties of the shape are animatable.
  var animatableData: AnimatablePair<CGFloat, CGFloat> {
    get { AnimatablePair(percent, phase) }
    set {
      percent = newValue.first
      phase = newValue.second
    }
  }

  // MARK: - Path Creation

  /// Creates the path for the wave shape within a given rectangle.
  func path(in rect: CGRect) -> Path {
    var path = Path()
    let waveHeight = rect.height * 0.03

    // Start from the bottom-left to create a closed shape for filling.
    path.move(to: CGPoint(x: 0, y: rect.height))
    path.addLine(to: CGPoint(x: 0, y: rect.height * (1 - percent)))

    // Draw the sine wave across the width of the rectangle.
    for x in stride(from: 0, through: rect.width, by: 1) {
      let relativeX = x / rect.width
      let sine = sin(relativeX * .pi * 2 + phase)
      let y = waveHeight * sine + rect.height * (1 - percent)
      path.addLine(to: CGPoint(x: x, y: y))
    }

    // Close the path by drawing lines to the bottom-right and back to the bottom-left.
    path.addLine(to: CGPoint(x: rect.width, y: rect.height))
    path.addLine(to: CGPoint(x: 0, y: rect.height))

    return path
  }
}
