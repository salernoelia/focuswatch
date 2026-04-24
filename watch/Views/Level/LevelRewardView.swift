import SwiftUI

struct LevelRewardView: View {
  let xpAmount: Int
  let title: String

  @StateObject private var levelService = LevelService.shared
  @State private var animatedXP: Int = 0
  @State private var displayLevel: Int = 1
  @State private var animatedProgress: Double = 0
  @State private var showLevelUpBadge = false
  @State private var startXP: Int = 0
  @State private var startLevel: Int = 1
  @State private var willLevelUp = false
  @State private var xpScale: CGFloat = 0.3
  @State private var xpOpacity: Double = 0
  @State private var starsVisible = false
  @State private var pulseScale: CGFloat = 1.0
  @State private var levelBumpScale: CGFloat = 1.0

  private let starPositions: [(CGFloat, CGFloat)] = [
    (-38, -18), (40, -14), (-28, 10), (36, 12), (0, -26)
  ]

  var body: some View {
    VStack(spacing: 6) {
      ZStack {
        ForEach(starPositions.indices, id: \.self) { i in
          let (x, y) = starPositions[i]
          Image(systemName: "star.fill")
            .font(.system(size: 9))
            .foregroundColor(.yellow.opacity(0.85))
            .offset(x: starsVisible ? x : 0, y: starsVisible ? y : 0)
            .scaleEffect(starsVisible ? 1 : 0)
            .opacity(starsVisible ? 1 : 0)
            .animation(
              .spring(response: 0.4, dampingFraction: 0.5)
                .delay(Double(i) * 0.06),
              value: starsVisible
            )
        }

        VStack(spacing: 2) {
          Text("Level \(displayLevel)")
            .font(.caption)
            .foregroundColor(.white.opacity(0.8))
            .scaleEffect(levelBumpScale)
            .animation(.spring(response: 0.3, dampingFraction: 0.45), value: displayLevel)

          Text("+\(animatedXP)")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.yellow)
            .scaleEffect(xpScale * pulseScale)
            .opacity(xpOpacity)

          Text("XP")
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.yellow.opacity(0.8))
            .opacity(xpOpacity)
        }
      }
      .frame(height: 70)

      progressBar
    }
    .onAppear {
      setupInitialState()
      startAnimation()
    }
  }

  private var progressBar: some View {
    VStack(spacing: 4) {
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          RoundedRectangle(cornerRadius: 6)
            .fill(Color.gray.opacity(0.25))
            .frame(height: 10)

          RoundedRectangle(cornerRadius: 6)
            .fill(
              LinearGradient(
                colors: [.green, .teal, .blue],
                startPoint: .leading,
                endPoint: .trailing
              )
            )
            .frame(width: geometry.size.width * animatedProgress, height: 10)
            .shadow(color: .green.opacity(0.5), radius: 4)
        }
      }
      .frame(height: 10)

      if let progress = levelService.currentProgress {
        HStack {
          Text(
            "\(Int(animatedProgress * Double(progress.xpNeededForNextLevel))) / \(progress.xpNeededForNextLevel)"
          )
          .font(.caption2)
          .foregroundColor(.secondary)
        }
      }
    }
  }

  private func setupInitialState() {
    guard let progress = levelService.currentProgress else { return }

    let finalXP = progress.currentXP
    let finalLevel = progress.currentLevel

    startXP = finalXP - xpAmount

    var calculatedStartLevel = finalLevel
    var tempXP = startXP

    while tempXP < 0 && calculatedStartLevel > 1 {
      calculatedStartLevel -= 1
      let xpNeeded = LevelProgress.xpForLevel(calculatedStartLevel + 1)
      tempXP += xpNeeded
    }

    startLevel = calculatedStartLevel
    startXP = max(0, tempXP)
    displayLevel = startLevel
    willLevelUp = finalLevel > startLevel

    let startLevelXPNeeded = LevelProgress.xpForLevel(startLevel + 1)
    animatedProgress = Double(startXP) / Double(startLevelXPNeeded)
  }

  private func startAnimation() {
    withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
      xpScale = 1.0
      xpOpacity = 1.0
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
      withAnimation(.spring(response: 0.35, dampingFraction: 0.4)) {
        starsVisible = true
      }
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
      withAnimation(.easeInOut(duration: 0.18).repeatCount(3, autoreverses: true)) {
        pulseScale = 1.12
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.54) {
        withAnimation(.spring()) {
          pulseScale = 1.0
        }
      }
    }

    guard let _ = levelService.currentProgress else { return }

    if willLevelUp {
      animateLevelUp()
    } else {
      animateNormalProgress()
    }

    animateXPCounter()
  }

  private func animateNormalProgress() {
    guard let progress = levelService.currentProgress else { return }
    let finalProgress = Double(progress.currentXP) / Double(progress.xpNeededForNextLevel)
    withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.3)) {
      animatedProgress = finalProgress
    }
  }

  private func animateLevelUp() {
    guard let progress = levelService.currentProgress else { return }

    let finalLevel = progress.currentLevel
    let finalXP = progress.currentXP

    var currentAnimationLevel = startLevel
    var currentAnimationXP = startXP
    var delay: Double = 0.3

    while currentAnimationLevel < finalLevel {
      let fillDuration = 0.7

      DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
          self.animatedProgress = 1.0
        }
      }

      delay += fillDuration

      let levelToShow = currentAnimationLevel + 1
      DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.38)) {
          self.displayLevel = levelToShow
          self.levelBumpScale = 1.4
          self.showLevelUpBadge = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
          withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            self.levelBumpScale = 1.0
          }
        }

        #if os(watchOS)
          VibrationManager.shared.playHaptic(.success)
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            VibrationManager.shared.playHaptic(.success)
          }
        #endif

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
          self.animatedProgress = 0
          self.showLevelUpBadge = false
        }
      }

      delay += 0.3
      currentAnimationLevel += 1
      currentAnimationXP = 0
    }

    let finalLevelXPNeeded = LevelProgress.xpForLevel(finalLevel + 1)
    let finalProgress = Double(finalXP) / Double(finalLevelXPNeeded)

    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
      withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
        self.animatedProgress = finalProgress
      }
    }
  }

  private func animateXPCounter() {
    let duration: Double = 1.0
    let steps = 50
    let stepDuration = duration / Double(steps)

    for i in 0...steps {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 + stepDuration * Double(i)) {
        let t = Double(i) / Double(steps)
        let eased = 1 - pow(1 - t, 3)
        animatedXP = Int(Double(xpAmount) * eased)
      }
    }
  }
}
