////
////  AvatarView.swift
////  FokusUhr Watch App
////
////  Created by Julian Amacker on 02.04.2024.

import Foundation
import SwiftUI

// MARK: - WritingColorView
/// The main container view that determines whether to show the start screen or the active run screen.
struct WritingColorView: View {
  // MARK: - Properties

  /// The environment object that manages the overall state of the exercise session.
  @EnvironmentObject var WritingExerciseManager: WritingExerciseManager
  let deviceUUIDPrefix = WatchConfig.shared.uuid.prefix(6)

  // MARK: - Body

  var body: some View {
    Group {
      // If the session is running but feedback is disabled, show a simple black screen.
      if WritingExerciseManager.showRunView && !UserConfigs.shared.configs.feedbackEnabled {
        Color.black.edgesIgnoringSafeArea(.all)
      }
      // If the session is running and feedback is enabled, show the main run view.
      else if WritingExerciseManager.showRunView {
        ColorRunView()
      } else {
        // If the session has not started, show the start button.
        GeometryReader { geometry in
          Button(action: {
            // Initialize the extended runtime session to allow background execution.
            WritingExerciseManager.initExtendedSession()

            // Delay the state change slightly to allow the button's pressed animation to show.
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
          .buttonStyle(PlainButtonStyle())  // Use plain style to have full control over the button's appearance.
        }
      }
    }
  }
}

// MARK: - ColorRunView
/// The view displayed during an active exercise session, showing progress with an animated wave.
struct ColorRunView: View {
  // MARK: - Properties

  @EnvironmentObject var WritingExerciseManager: WritingExerciseManager
    private let deviceUUIDPrefix = WatchConfig.shared.uuid.prefix(6)
  var currentSetting = UserConfigs.shared.configs

  /// The state variable that drives the wave animation's phase.
  @State private var wavePhase: CGFloat = 0.0

  // MARK: - Body

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        // Main view during an active session (not ended).
        if WritingExerciseManager.exerciseState != .ended {
          Color.black.edgesIgnoringSafeArea(.all)

          // A grey circle that serves as the background/track for the progress indicator.
          Circle()
            .fill(Color.gray)
            .frame(width: geometry.size.width * 0.8, height: geometry.size.width * 0.8)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

          // The main progress circle, which changes color based on the exercise state.
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
            .frame(width: geometry.size.width * 0.8, height: geometry.size.width * 0.8)
            .overlay(
              // The animated wave shape that "fills" the circle.
              WaveShape(percent: getFillPercentage(), phase: wavePhase)
                .fill(Color.white.opacity(0.8))
                .scaleEffect(x: 1.0, y: -1.0, anchor: .center)  // Flip vertically to fill from the bottom.
            )
            .mask(Circle())  // Ensure the wave stays within the circle bounds.
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

        } else {
          // View shown when the exercise session has ended.
          Color.black.edgesIgnoringSafeArea(.all)

          Circle()
            .fill(Color.gray)
            .frame(width: geometry.size.width * 0.8, height: geometry.size.width * 0.8)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

          // A purple circle indicating completion.
          Circle()
            .fill(
              LinearGradient(
                gradient: Gradient(colors: [Color.purple, Color.purple.opacity(0.7)]),
                startPoint: .top,
                endPoint: .bottom
              )
            )
            .frame(width: geometry.size.width * 0.8, height: geometry.size.width * 0.8)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

          // A trophy emoji to celebrate completion.
          VStack {
            Spacer()
            Text("🏆")
              .foregroundColor(.white)
              .font(.system(size: 64))
              .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
          }
        }
      }
      .onAppear {
        // Start a repeating linear animation for the wave phase.
        withAnimation(Animation.linear(duration: 4.0).repeatForever(autoreverses: false)) {
          wavePhase = .pi * 2
        }
      }
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

// MARK: - ColorRunViewNoWave
/// A non-animated alternative to `ColorRunView` that uses a simple rectangle mask for the fill effect.
struct ColorRunViewNoWave: View {
  // MARK: - Properties

  @EnvironmentObject var WritingExerciseManager: WritingExerciseManager
    private let deviceUUIDPrefix = WatchConfig.shared.uuid.prefix(6) 
  var currentSetting = UserConfigs.shared.configs

  // MARK: - Body

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        if WritingExerciseManager.exerciseState != .ended {
          Color.black.edgesIgnoringSafeArea(.all)

          Circle()
            .fill(Color.gray)
            .frame(width: geometry.size.width * 0.8, height: geometry.size.width * 0.8)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

          // The main colored circle.
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
            .frame(width: geometry.size.width * 0.8, height: geometry.size.width * 0.8)
            .mask(
              // The fill effect is created by masking the circle with a VStack containing a Spacer and a Rectangle.
              // The height of the Spacer changes, revealing more or less of the circle.
              VStack {
                Spacer(minLength: getTopPadding(for: geometry.size.width * 0.8))
                Rectangle()
              }
            )
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        } else {
          // End-of-session view, same as in the animated version.
          Color.black.edgesIgnoringSafeArea(.all)

          Circle()
            .fill(Color.gray)
            .frame(width: geometry.size.width * 0.8, height: geometry.size.width * 0.8)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

          Circle()
            .fill(
              LinearGradient(
                gradient: Gradient(colors: [Color.purple, Color.purple.opacity(0.7)]),
                startPoint: .top,
                endPoint: .bottom
              )
            )
            .frame(width: geometry.size.width * 0.8, height: geometry.size.width * 0.8)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
          VStack {
            Spacer()
            if WritingExerciseManager.exerciseState == .ended {
              Text("🏆")
                .foregroundColor(.white)
                .font(.system(size: 64))
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
          }
        }
      }
    }
  }

  // MARK: - Helper Methods

  /// Calculates the top padding for the mask, which determines the fill level.
  private func getTopPadding(for diameter: CGFloat) -> CGFloat {
    let totalAreaHeight = diameter
    let margin = totalAreaHeight * 0.05  // A small margin at the bottom.
    let availableHeight = totalAreaHeight - margin
    let percentage: Double
    let timePercentage: Double

    if WritingExerciseManager.exerciseState == .pausing {
      // During pause, the fill level is based on the pause timer.
      let pauseTimePercentage =
        Double(WritingExerciseManager.currentPauseTime) / Double(currentSetting.pause * 60)
      percentage = pauseTimePercentage
    } else {
      // During work, the fill level is based on the work timer.
      if WritingExerciseManager.pomodoro {
        timePercentage =
          Double(WritingExerciseManager.currentTime) / Double(currentSetting.learn * 60)
        percentage = timePercentage
      } else {
        let timeWorked = WritingExerciseManager.totalWorkTime()
        timePercentage = Double(timeWorked) / Double(currentSetting.learn * 60)
        percentage = 1 - timePercentage
      }
    }
    // The padding is the inverse of the fill percentage.
    return totalAreaHeight - (margin + (availableHeight * percentage))
  }
}
