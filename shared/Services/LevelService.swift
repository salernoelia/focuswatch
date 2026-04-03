import Foundation
import SwiftData
import UserNotifications

#if os(watchOS)
    import WatchKit
#endif

@MainActor
class LevelService: ObservableObject {
    static let shared = LevelService()

    @Published var currentProgress: LevelProgress?

    private let container: ModelContainer
    internal let context: ModelContext

    #if os(watchOS)
        private let vibrationManager = VibrationManager.shared
    #endif
    private let loadMilestones: () -> [LevelMilestone]
    #if os(watchOS)
        private let notifyLevelChange: () -> Void
    #endif

    private init(
        loadMilestones: (() -> [LevelMilestone])? = nil,
        notifyLevelChange: (() -> Void)? = nil
    ) {
        self.loadMilestones =
            loadMilestones
            ?? {
                #if os(watchOS)
                    return SyncCoordinator.shared.loadLevelMilestones()
                #else
                    return LevelSyncService.shared.loadLevelData().milestones
                #endif
            }
        #if os(watchOS)
            self.notifyLevelChange =
                notifyLevelChange
                ?? {
                    SyncCoordinator.shared.syncLevelToiOS()
                }
        #endif

        let schema = Schema([
            LevelProgress.self,
            ActivityStats.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            container = try ModelContainer(for: schema, configurations: [config])
            context = ModelContext(container)
            loadOrCreateProgress()
        } catch {
            fatalError("Failed to initialize LevelService: \(error)")
        }
    }

    private func loadOrCreateProgress() {
        let descriptor = FetchDescriptor<LevelProgress>()

        do {
            let results = try context.fetch(descriptor)

            if let existing = results.first {
                currentProgress = existing
            } else {
                let newProgress = LevelProgress()
                context.insert(newProgress)
                try context.save()
                currentProgress = newProgress
            }
        } catch {
            #if DEBUG
                ErrorLogger.log(
                    AppError.databaseQueryFailed(
                        operation: "fetch LevelProgress", underlying: error))
            #endif
        }
    }

    func addXP(_ amount: Int, reason: String = "") {
        guard let progress = currentProgress, amount > 0 else { return }

        let oldLevel = progress.currentLevel
        progress.currentXP += amount
        progress.totalXP += amount
        progress.lastUpdated = Date()

        #if os(watchOS)
            vibrationManager.playHaptic(.click)
        #endif

        while progress.currentXP >= progress.xpNeededForNextLevel {
            progress.currentXP -= progress.xpNeededForNextLevel
            progress.currentLevel += 1
        }

        if progress.currentLevel > oldLevel {
            handleLevelUp(newLevel: progress.currentLevel)
        }

        saveProgress()
        objectWillChange.send()

        #if os(watchOS)
            notifyiOSOfLevelChange()
        #endif

        #if DEBUG
            let logReason = reason.isEmpty ? "" : " (\(reason))"
            ErrorLogger.log(
                "✨ +\(amount) Points\(logReason) | Level \(progress.currentLevel) | \(progress.currentXP)/\(progress.xpNeededForNextLevel) Points"
            )
        #endif
    }

    #if os(watchOS)
        private func notifyiOSOfLevelChange() {
            notifyLevelChange()
        }
    #endif

    private func handleLevelUp(newLevel: Int) {
        #if os(watchOS)
            vibrationManager.playHaptic(.success)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.vibrationManager.playHaptic(.success)
            }
        #endif

        let unlockedMilestones = checkUnlockedMilestones(at: newLevel)
        sendLevelUpNotification(level: newLevel, milestones: unlockedMilestones)
    }

    private func checkUnlockedMilestones(at level: Int) -> [LevelMilestone] {
        let milestones = loadMilestones()

        return milestones.filter { $0.isEnabled && $0.levelRequired == level }
    }

    private func sendLevelUpNotification(level: Int, milestones: [LevelMilestone]) {
        let content = UNMutableNotificationContent()

        if !milestones.isEmpty {
            if milestones.count == 1 {
                content.title = String(localized: "🏆 \(milestones[0].title)")
                content.body = String(localized: "Level \(level) reached!")
            } else {
                content.title = String(
                    localized: "🏆 Level \(level) - \(milestones.count) Milestones!")
                let milestoneNames = milestones.map { $0.title }.joined(separator: ", ")
                content.body = milestoneNames
            }
        } else {
            content.title = String(localized: "Level \(level) reached!")
            content.body = String(localized: "You have unlocked a new Level!")
        }

        content.sound = .default
        content.categoryIdentifier = milestones.isEmpty ? "LEVEL_UP" : "MILESTONE"

        let request = UNNotificationRequest(
            identifier: "levelUp_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            #if DEBUG
                if let error = error {
                    ErrorLogger.log(AppError.unknown(underlying: error))
                }
            #endif
        }
    }

    private func saveProgress() {
        do {
            try context.save()
        } catch {
            #if DEBUG
                ErrorLogger.log(
                    AppError.databaseQueryFailed(operation: "save LevelProgress", underlying: error)
                )
            #endif
        }
    }

    func resetProgress() {
        guard let progress = currentProgress else { return }

        progress.currentLevel = 1
        progress.currentXP = 0
        progress.totalXP = 0
        progress.lastUpdated = Date()

        saveProgress()
        objectWillChange.send()
    }
}
