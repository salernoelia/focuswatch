import SwiftUI
import UserNotifications

struct CalendarEntryTriggerConsent: View {
    let event: EventTransfer
    let reminder: Reminder
    let shouldAutoLaunch: Bool
    @StateObject private var appsManager = AppsManager.shared
    @StateObject private var calendarManager = CalendarViewModel.shared
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var syncCoordinator: SyncCoordinator
    @State private var isLaunching = false

    private var appTitle: String {
        if let appIndex = event.appIndex,
           let app = appsManager.apps.first(where: { $0.index == appIndex }) {
            return app.title
        }
        return "this activity"
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(event.title)
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            if let description = event.eventDescription, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let appIndex = event.appIndex {
                Button {
                    guard !isLaunching else { return }
                    isLaunching = true
                    syncCoordinator.currentView = .app(appIndex)
                    dismiss()
                } label: {
                    Text("Starten")
                }
                .tint(.green)
                .buttonStyle(.borderedProminent)
                .disabled(isLaunching)
            }

            Button {
                scheduleSnoozeNotification()
                dismiss()
            } label: {
                Text("In 5 minutes")
            }
            .buttonStyle(.bordered)
            .disabled(isLaunching)
        }
        .onAppear {
            if shouldAutoLaunch, let appIndex = event.appIndex {
                isLaunching = true
                syncCoordinator.currentView = .app(appIndex)
                dismiss()
            }
        }
    }

    private func scheduleSnoozeNotification() {
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
        content.userInfo = [
            "eventId": event.id.uuidString,
            "reminderId": reminder.id.uuidString,
            "shouldLaunchApp": reminder.shouldLaunchApp,
        ]

        if reminder.shouldLaunchApp && event.appIndex != nil {
            content.categoryIdentifier = "CALENDAR_REMINDER_LAUNCH"
        } else {
            content.categoryIdentifier = "CALENDAR_REMINDER"
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 300, repeats: false)
        let identifier = "snooze-\(event.id.uuidString)-\(reminder.id.uuidString)-\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { _ in }
    }
}

#Preview {
    CalendarEntryTriggerConsent(
        event: EventTransfer(
            id: UUID(),
            title: "Mathe Hausaufgaben",
            eventDescription: "Seite 42-45 lösen",
            date: Date(),
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600),
            repeatRule: .none,
            customWeekdays: [],
            appIndex: 0,
            reminders: []
        ),
        reminder: Reminder(minutesBefore: 10),
        shouldAutoLaunch: false,
        syncCoordinator: SyncCoordinator.shared
    )
}
