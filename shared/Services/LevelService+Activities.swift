import Foundation

extension LevelService {
    enum ActivityType: String {
        case checklistCompleted = "Checklist abgeschlossen"
        case pomodoroCompleted = "Pomodoro abgeschlossen"
        case writingSession = "Schreibübung"
        case breathingExercise = "Atemübung"
        case fidgetUsed = "Fidget verwendet"
        case calendarEventCreated = "Kalendereintrag erstellt"
        case journalEntry = "Tagebucheintrag"
        case custom

        var xpReward: Int {
            switch self {
            case .checklistCompleted: return 50
            case .pomodoroCompleted: return 100
            case .writingSession: return 75
            case .breathingExercise: return 30
            case .fidgetUsed: return 10
            case .calendarEventCreated: return 25
            case .journalEntry: return 40
            case .custom: return 0
            }
        }

        var appName: String {
            switch self {
            case .checklistCompleted: return "Checklist"
            case .pomodoroCompleted: return "Pomodoro"
            case .writingSession: return "Writing"
            case .breathingExercise: return "Breathing"
            case .fidgetUsed: return "Fidget Toy"
            case .calendarEventCreated: return "Calendar"
            case .journalEntry: return "Journal"
            case .custom: return "Custom"
            }
        }
    }

    func awardXP(for activity: ActivityType, customAmount: Int = 0) {
        let amount = activity == .custom ? customAmount : activity.xpReward
        addXP(amount, reason: activity.rawValue)

        if activity != .custom {
            recordActivity(
                appName: activity.appName, activityType: activity.rawValue, xpEarned: amount)
        }
    }

    func publishActivity(appName: String, activityName: String, xpAmount: Int) {
        addXP(xpAmount, reason: "\(appName): \(activityName)")
        recordActivity(appName: appName, activityType: activityName, xpEarned: xpAmount)
    }
}
