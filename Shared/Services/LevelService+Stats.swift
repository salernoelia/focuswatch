import Foundation
import SwiftData

extension LevelService {
  func recordActivity(appName: String, activityType: String, xpEarned: Int) {
    let descriptor = FetchDescriptor<ActivityStats>(
      predicate: #Predicate<ActivityStats> { stats in
        stats.appName == appName && stats.activityType == activityType
      }
    )

    do {
      let results = try context.fetch(descriptor)

      if let existing = results.first {
        existing.count += 1
        existing.totalXPEarned += xpEarned
        existing.lastActivityDate = Date()
      } else {
        let newStats = ActivityStats(
          appName: appName,
          activityType: activityType,
          count: 1,
          totalXPEarned: xpEarned
        )
        context.insert(newStats)
      }

      try context.save()

      #if DEBUG
        ErrorLogger.log("📊 Recorded activity: \(appName) - \(activityType)")
      #endif
    } catch {
      #if DEBUG
        ErrorLogger.log(
          AppError.databaseQueryFailed(operation: "record activity", underlying: error))
      #endif
    }
  }

  func getStats(for appName: String) -> [ActivityStats] {
    let descriptor = FetchDescriptor<ActivityStats>(
      predicate: #Predicate<ActivityStats> { stats in
        stats.appName == appName
      }
    )

    do {
      return try context.fetch(descriptor)
    } catch {
      #if DEBUG
        ErrorLogger.log(AppError.databaseQueryFailed(operation: "fetch stats", underlying: error))
      #endif
      return []
    }
  }

  func getAllStats() -> [ActivityStats] {
    let descriptor = FetchDescriptor<ActivityStats>()

    do {
      return try context.fetch(descriptor)
    } catch {
      #if DEBUG
        ErrorLogger.log(
          AppError.databaseQueryFailed(operation: "fetch all stats", underlying: error))
      #endif
      return []
    }
  }
}
