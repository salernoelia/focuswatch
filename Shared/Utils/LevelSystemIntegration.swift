import Foundation

protocol LevelSystemIntegration {
  var appName: String { get }

  func publishActivity(name: String, xpAmount: Int)
}

extension LevelSystemIntegration {
  func publishActivity(name: String, xpAmount: Int) {
    Task { @MainActor in
      LevelService.shared.publishActivity(
        appName: appName,
        activityName: name,
        xpAmount: xpAmount
      )
    }
  }
}

struct ActivityEvent {
  let appName: String
  let activityName: String
  let xpAmount: Int
  let timestamp: Date
  let metadata: [String: Any]?

  init(
    appName: String,
    activityName: String,
    xpAmount: Int,
    timestamp: Date = Date(),
    metadata: [String: Any]? = nil
  ) {
    self.appName = appName
    self.activityName = activityName
    self.xpAmount = xpAmount
    self.timestamp = timestamp
    self.metadata = metadata
  }

  func publish() {
    Task { @MainActor in
      LevelService.shared.publishActivity(
        appName: appName,
        activityName: activityName,
        xpAmount: xpAmount
      )
    }
  }
}
