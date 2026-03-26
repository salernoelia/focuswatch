import Foundation
import SwiftData

@Model
final class ActivityStats {
  var id: UUID
  var appName: String
  var activityType: String
  var count: Int
  var totalXPEarned: Int
  var lastActivityDate: Date
  var firstActivityDate: Date

  init(
    id: UUID = UUID(),
    appName: String,
    activityType: String,
    count: Int = 0,
    totalXPEarned: Int = 0,
    lastActivityDate: Date = Date(),
    firstActivityDate: Date = Date()
  ) {
    self.id = id
    self.appName = appName
    self.activityType = activityType
    self.count = count
    self.totalXPEarned = totalXPEarned
    self.lastActivityDate = lastActivityDate
    self.firstActivityDate = firstActivityDate
  }
}
