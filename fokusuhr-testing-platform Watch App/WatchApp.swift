import SwiftUI
import UserNotifications
import WatchKit

@main
struct WatchApp: App {
    @StateObject private var syncCoordinator = SyncCoordinator.shared
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
                .environmentObject(syncCoordinator)
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
                            shouldAutoLaunch: pending.shouldAutoLaunch,
                            syncCoordinator: syncCoordinator
                        )
                    }
                }
                .onChange(of: scenePhase, initial: false) { oldPhase, newPhase in
                    if newPhase == .active {
                        syncCoordinator.forceReconnect()
                        Task {
                            await calendarManager.rescheduleIfNeeded()
                            await scheduleBackgroundRefresh()
                        }
                    }
                }
        }
        .backgroundTask(.appRefresh("org.fokusuhr.refresh")) { _ in
            await calendarManager.rescheduleIfNeeded()
            await scheduleBackgroundRefresh()
        }
    }

    private func scheduleBackgroundRefresh() async {
        let preferredDate = Calendar.current.date(byAdding: .hour, value: 6, to: Date()) ?? Date()
        do {
            try await WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: preferredDate, userInfo: nil)
        } catch {
            #if DEBUG
            print("Failed to schedule background refresh: \(error)")
            #endif
        }
    }

    private func setupNotifications() {
        UNUserNotificationCenter.current().delegate = NotificationHandler.shared

        let launchAction = UNNotificationAction(
            identifier: "LAUNCH_ACTION",
            title: String(localized: "Start"),
            options: [.foreground]
        )

        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: String(localized: "In 5 minutes"),
            options: []
        )

        let launchCategory = UNNotificationCategory(
            identifier: "CALENDAR_REMINDER_LAUNCH",
            actions: [launchAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )

        let reminderCategory = UNNotificationCategory(
            identifier: "CALENDAR_REMINDER",
            actions: [snoozeAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([launchCategory, reminderCategory])
    }

    private func syncWatchIdToWidget() {
        let sharedDefaults = UserDefaults(suiteName: "group.net.com.fokusuhr")
        let uuid = WatchConfig.shared.uuid
        sharedDefaults?.set(uuid, forKey: "deviceUUID")
        sharedDefaults?.synchronize()
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
                  let reminderId = UUID(uuidString: reminderIdString) {
            DispatchQueue.main.async {
                if response.actionIdentifier == "SNOOZE_ACTION" {
                    self.scheduleSnoozeNotification(
                        eventId: eventId,
                        reminderId: reminderId,
                        userInfo: userInfo
                    )
                } else {
                    let shouldLaunch = response.actionIdentifier == "LAUNCH_ACTION"

                    CalendarViewModel.shared.handleReminderResponse(
                        eventId: eventId,
                        reminderId: reminderId,
                        shouldLaunch: shouldLaunch
                    )
                }
            }
        }

        completionHandler()
    }

    private func scheduleSnoozeNotification(
        eventId: UUID,
        reminderId: UUID,
        userInfo: [AnyHashable: Any]
    ) {
        guard let event = CalendarViewModel.shared.events.first(where: { $0.id == eventId }),
              let reminder = event.reminders.first(where: { $0.id == reminderId })
        else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = event.title

        if let description = event.eventDescription, !description.isEmpty {
            content.body = description
        } else if let message = reminder.message, !message.isEmpty {
            content.body = message
        } else {
            content.body = String(localized: "Reminder")
        }

        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.userInfo = userInfo

        if reminder.shouldLaunchApp && event.appIndex != nil {
            content.categoryIdentifier = "CALENDAR_REMINDER_LAUNCH"
        } else {
            content.categoryIdentifier = "CALENDAR_REMINDER"
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 300, repeats: false)
        let identifier = "snooze-\(eventId.uuidString)-\(reminderId.uuidString)-\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { _ in }
    }
}
