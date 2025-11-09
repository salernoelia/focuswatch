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

  var body: some View {
    VStack(spacing: 4) {
      ZStack {
        Text("Level \(displayLevel)")
          .font(.title3)
          .fontWeight(.bold)
          .foregroundColor(.white)
      }
      .frame(height: 20)

      Text("+\(animatedXP) XP")
        .font(.title2)
        .fontWeight(.bold)
        .foregroundColor(.yellow)

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
          RoundedRectangle(cornerRadius: 4)
            .fill(Color.gray.opacity(0.3))
            .frame(height: 8)

          RoundedRectangle(cornerRadius: 4)
            .fill(
              LinearGradient(
                colors: [.green, .blue],
                startPoint: .leading,
                endPoint: .trailing
              )
            )
            .frame(width: geometry.size.width * animatedProgress, height: 8)
        }
      }
      .frame(height: 8)

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
    guard let progress = levelService.currentProgress else { return }

    let currentXP = progress.currentXP
    let xpNeeded = progress.xpNeededForNextLevel
    let finalProgress = Double(currentXP) / Double(xpNeeded)

    if willLevelUp {
      animateLevelUp()
    } else {
      animateNormalProgress(to: finalProgress)
    }

    animateXPCounter()
  }

  private func animateNormalProgress(to finalProgress: Double) {
    withAnimation(.easeOut(duration: 1.2)) {
      animatedProgress = finalProgress
    }
  }

  private func animateLevelUp() {
    guard let progress = levelService.currentProgress else { return }

    let finalLevel = progress.currentLevel
    let finalXP = progress.currentXP

    var currentAnimationLevel = startLevel
    var currentAnimationXP = startXP
    var delay: Double = 0

    while currentAnimationLevel < finalLevel {
      let xpNeeded = LevelProgress.xpForLevel(currentAnimationLevel + 1)
      let xpToFill = xpNeeded - currentAnimationXP

      let fillDuration = 0.8

      DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        withAnimation(.easeOut(duration: fillDuration)) {
          self.animatedProgress = 1.0
        }
      }

      delay += fillDuration

      let levelToShow = currentAnimationLevel + 1
      DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
          self.displayLevel = levelToShow
          self.showLevelUpBadge = true
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
      withAnimation(.easeOut(duration: 0.6)) {
        self.animatedProgress = finalProgress
      }
    }
  }

  private func animateXPCounter() {
    let duration: Double = 1.2
    let steps = 60
    let stepDuration = duration / Double(steps)

    for i in 0...steps {
      DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
        let progress = Double(i) / Double(steps)
        animatedXP = Int(Double(xpAmount) * progress)
      }
    }
  }
}
