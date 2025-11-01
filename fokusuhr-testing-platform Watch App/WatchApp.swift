import SwiftUI
import UserNotifications

@main
struct WatchApp: App {
  @StateObject private var watchConnector = WatchConnector()
  @StateObject private var writingExerciseManager = WritingExerciseManager()
  @StateObject private var calendarManager = CalendarViewModel.shared
  @Environment(\.scenePhase) private var scenePhase

  init() {
    setupNotifications()
  }

  var body: some Scene {
    WindowGroup {
      WatchView()
        .environmentObject(watchConnector)
        .environmentObject(writingExerciseManager)
        .sheet(
          isPresented: Binding(
            get: { calendarManager.pendingReminder != nil },
            set: { if !$0 { calendarManager.pendingReminder = nil } }
          )
        ) {
          if let pending = calendarManager.pendingReminder {
            CalendarEntryTriggerConsent(
              event: pending.event,
              reminder: pending.reminder,
              watchConnector: watchConnector
            )
          }
        }
        .onChange(of: scenePhase, initial: false) { oldPhase, newPhase in
          if newPhase == .active {
            #if DEBUG
              print("🔄 App became active - checking for calendar updates...")
            #endif
            watchConnector.forceReconnect()
          }
        }
    }
  }

  private func setupNotifications() {
    UNUserNotificationCenter.current().delegate = NotificationHandler.shared
  }
}

class NotificationHandler: NSObject, UNUserNotificationCenterDelegate {
  static let shared = NotificationHandler()

  private override init() {
    super.init()
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .sound])
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo

    if response.notification.request.identifier == "pomodoroTimer" {
      Task { @MainActor in
        if PomodoroViewModel.shared.timeRemaining <= 0 {
          await PomodoroViewModel.shared.handleTimerCompletion()
        }
      }
    } else if let eventIdString = userInfo["eventId"] as? String,
      let eventId = UUID(uuidString: eventIdString),
      let reminderIdString = userInfo["reminderId"] as? String,
      let reminderId = UUID(uuidString: reminderIdString)
    {
      DispatchQueue.main.async {
        let shouldLaunch = response.actionIdentifier == UNNotificationDefaultActionIdentifier
        CalendarViewModel.shared.handleReminderResponse(
          eventId: eventId,
          reminderId: reminderId,
          shouldLaunch: shouldLaunch
        )
      }
    }

    completionHandler()
  }
}
