import SwiftUI
import UserNotifications

@main
struct WatchApp: App {
  @StateObject private var watchConnector = WatchConnector.shared
  @StateObject private var writingExerciseManager = WritingExerciseManager()
  @StateObject private var calendarManager = CalendarViewModel.shared
  @Environment(\.scenePhase) private var scenePhase

  init() {
    setupNotifications()
    syncWatchIdToWidget()
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

    let launchAction = UNNotificationAction(
      identifier: "LAUNCH_ACTION",
      title: String(localized: "Start"),
      options: [.foreground]
    )

    let dismissAction = UNNotificationAction(
      identifier: "DISMISS_ACTION",
      title: String(localized: "Later"),
      options: []
    )

    let launchCategory = UNNotificationCategory(
      identifier: "CALENDAR_REMINDER_LAUNCH",
      actions: [launchAction, dismissAction],
      intentIdentifiers: [],
      options: []
    )

    let reminderCategory = UNNotificationCategory(
      identifier: "CALENDAR_REMINDER",
      actions: [dismissAction],
      intentIdentifiers: [],
      options: []
    )

    UNUserNotificationCenter.current().setNotificationCategories([launchCategory, reminderCategory])

    #if DEBUG
      print("🔔 Notification categories registered")
    #endif
  }

  private func syncWatchIdToWidget() {
    let sharedDefaults = UserDefaults(suiteName: "group.net.com.fokusuhr")
    let uuid = WatchConfig.shared.uuid
    sharedDefaults?.set(uuid, forKey: "deviceUUID")
    sharedDefaults?.synchronize()

    #if DEBUG
      print("⌚ WatchApp: Synced UUID to widget: \(String(uuid.prefix(8)))")
    #endif
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
        let shouldLaunch =
          response.actionIdentifier == UNNotificationDefaultActionIdentifier
          || response.actionIdentifier == "LAUNCH_ACTION"

        #if DEBUG
          print("🔔 Calendar notification tapped")
          print("   → Action: \(response.actionIdentifier)")
          print("   → Should launch: \(shouldLaunch)")
          print("   → Event ID: \(eventId)")
        #endif

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
