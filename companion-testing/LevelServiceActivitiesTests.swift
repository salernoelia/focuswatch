import Foundation
import Testing

@testable import focuswatch_companion

@Suite("LevelService ActivityType")
struct LevelServiceActivitiesTests {
        @Test("checklistCompleted xp reward is 50")
        func checklistCompletedXPRewardIs50() {
            #expect(LevelService.ActivityType.checklistCompleted.xpReward == 50)
        }

        @Test("pomodoroCompleted xp reward is 100")
        func pomodoroCompletedXPRewardIs100() {
            #expect(LevelService.ActivityType.pomodoroCompleted.xpReward == 100)
        }

        @Test("writingSession xp reward is 75")
        func writingSessionXPRewardIs75() {
            #expect(LevelService.ActivityType.writingSession.xpReward == 75)
        }

        @Test("breathingExercise xp reward is 30")
        func breathingExerciseXPRewardIs30() {
            #expect(LevelService.ActivityType.breathingExercise.xpReward == 30)
        }

        @Test("fidgetUsed xp reward is 10")
        func fidgetUsedXPRewardIs10() {
            #expect(LevelService.ActivityType.fidgetUsed.xpReward == 10)
        }

        @Test("calendarEventCreated xp reward is 25")
        func calendarEventCreatedXPRewardIs25() {
            #expect(LevelService.ActivityType.calendarEventCreated.xpReward == 25)
        }

        @Test("journalEntry xp reward is 40")
        func journalEntryXPRewardIs40() {
            #expect(LevelService.ActivityType.journalEntry.xpReward == 40)
        }

        @Test("custom xp reward is 0")
        func customXPRewardIsZero() {
            #expect(LevelService.ActivityType.custom.xpReward == 0)
        }

        @Test("appName is non-empty for all cases")
        func appNameIsNonEmptyForAllCases() {
            let cases: [LevelService.ActivityType] = [
                .checklistCompleted, .pomodoroCompleted, .writingSession,
                .breathingExercise, .fidgetUsed, .calendarEventCreated,
                .journalEntry, .custom
            ]
            for activity in cases {
                #expect(!activity.appName.isEmpty)
            }
        }
}
