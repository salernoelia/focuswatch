import Foundation
import Testing

@testable import focuswatch_companion

@Suite("LevelProgress Model")
struct LevelProgressModelTests {
        @Test("xpForLevel scales linearly by 100 per level")
        func xpForLevelScalesLinearly() {
            #expect(LevelProgress.xpForLevel(1) == 100)
            #expect(LevelProgress.xpForLevel(5) == 500)
            #expect(LevelProgress.xpForLevel(10) == 1000)
        }

        @Test("xpNeededForNextLevel is current level + 1 * 100")
        func xpNeededForNextLevelIsCurrentLevelPlusOne() {
            let progress = LevelProgress(currentLevel: 3, currentXP: 0)
            #expect(progress.xpNeededForNextLevel == 400)
        }

        @Test("progressToNextLevel is zero at start")
        func progressToNextLevelIsZeroAtStart() {
            let progress = LevelProgress(currentLevel: 1, currentXP: 0)
            #expect(progress.progressToNextLevel == 0.0)
        }

        @Test("progressToNextLevel is correct fraction")
        func progressToNextLevelIsCorrectFraction() {
            let progress = LevelProgress(currentLevel: 1, currentXP: 100)
            #expect(abs(progress.progressToNextLevel - 0.5) < 0.0001)
        }

        @Test("progressToNextLevel caps at 1.0 when xp equals threshold")
        func progressToNextLevelCapsAtOne() {
            let progress = LevelProgress(currentLevel: 1, currentXP: 200)
            #expect(progress.progressToNextLevel == 1.0)
        }

        @Test("progressToNextLevel guard against zero denominator")
        func progressToNextLevelGuardsAgainstZeroDenominator() {
            let progress = LevelProgress(currentLevel: 0, currentXP: 0)
            #expect(progress.progressToNextLevel == 0.0)
        }
}
