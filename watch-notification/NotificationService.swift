import UserNotifications

class NotificationService: UNNotificationServiceExtension {

  var contentHandler: ((UNNotificationContent) -> Void)?
  var bestAttemptContent: UNMutableNotificationContent?

  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    self.contentHandler = contentHandler
    bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

    if let bestAttemptContent = bestAttemptContent {
      if bestAttemptContent.userInfo["eventId"] as? String != nil,
        let shouldLaunchApp = bestAttemptContent.userInfo["shouldLaunchApp"] as? Bool
      {

        if shouldLaunchApp {
          bestAttemptContent.categoryIdentifier = "CALENDAR_REMINDER_LAUNCH"
        } else {
          bestAttemptContent.categoryIdentifier = "CALENDAR_REMINDER"
        }
      }

      contentHandler(bestAttemptContent)
    }
  }

  override func serviceExtensionTimeWillExpire() {
    if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
      contentHandler(bestAttemptContent)
    }
  }

}
