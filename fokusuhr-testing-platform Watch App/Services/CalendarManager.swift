import Foundation
import UserNotifications

class CalendarManager: ObservableObject {
  @Published var events: [EventTransfer] = []
  @Published var pendingReminder: (event: EventTransfer, reminder: Reminder)?

  static let shared = CalendarManager()

  private init() {
    loadEvents()
    requestNotificationPermissions()
  }

  func updateEvents(_ newEvents: [EventTransfer]) {
    DispatchQueue.main.async {
      self.events = newEvents
      self.saveEvents()
      self.scheduleAllReminders()
    }
  }

  private func requestNotificationPermissions() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
      granted, error in
      #if DEBUG
        print("📢 Notification permission granted: \(granted)")
        if let error = error {
          ErrorLogger.log("Notification permission error: \(error)")
        }
      #endif
    }
  }

  func scheduleTestNotification() {
    let content = UNMutableNotificationContent()
    content.title = "Test Event"
    content.body = "This is a test notification"
    content.sound = .default

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
    let request = UNNotificationRequest(
      identifier: "test-notification", content: content, trigger: trigger)

    UNUserNotificationCenter.current().add(request) { error in
      if let error = error {
        #if DEBUG
          print("❌ Failed to schedule test notification: \(error)")
        #endif
      } else {
        #if DEBUG
          print("✅ Test notification scheduled for 5 seconds from now")
        #endif
      }
    }
  }

  func scheduleAllReminders() {
    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

    for event in events {
      scheduleReminders(for: event)
    }
  }

  private func scheduleReminders(for event: EventTransfer) {
    for reminder in event.reminders {
      scheduleReminder(for: event, reminder: reminder)
    }
  }

  private func scheduleReminder(for event: EventTransfer, reminder: Reminder) {
    let content = UNMutableNotificationContent()
    content.title = event.title
    content.body = "Startet in \(reminder.minutesBefore) Minuten"
    content.sound = .default
    content.userInfo = [
      "eventId": event.id.uuidString,
      "reminderId": reminder.id.uuidString,
      "appIndex": event.appIndex as Any,
      "shouldLaunchApp": reminder.shouldLaunchApp,
    ]

    let triggerDate = Calendar.current.date(
      byAdding: .minute, value: -reminder.minutesBefore, to: event.startTime)

    guard let triggerDate = triggerDate, triggerDate > Date() else {
      #if DEBUG
        print("⏭️ Skipping reminder for \(event.title) - trigger date in past")
      #endif
      return
    }

    let components = Calendar.current.dateComponents(
      [.year, .month, .day, .hour, .minute], from: triggerDate)
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

    let identifier = "\(event.id.uuidString)-\(reminder.id.uuidString)"
    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

    UNUserNotificationCenter.current().add(request) { error in
      if let error = error {
        #if DEBUG
          ErrorLogger.log("Failed to schedule reminder: \(error)")
        #endif
      } else {
        #if DEBUG
          print("✅ Scheduled reminder for \(event.title) at \(triggerDate)")
        #endif
      }
    }
  }

  func handleReminderResponse(eventId: UUID, reminderId: UUID, shouldLaunch: Bool) {
    guard let event = events.first(where: { $0.id == eventId }),
      let reminder = event.reminders.first(where: { $0.id == reminderId })
    else { return }

    if shouldLaunch {
      pendingReminder = (event, reminder)
    }
  }

  func events(on day: Date) -> [EventTransfer] {
    let cal = Calendar.current
    var matchingEvents: [EventTransfer] = []

    for event in events {
      if cal.isDate(event.date, inSameDayAs: day) {
        matchingEvents.append(event)
      } else if event.repeatRule != .none && shouldRepeatOn(event: event, date: day) {
        let repeatedEvent = EventTransfer(
          id: event.id,
          title: event.title,
          date: day,
          startTime: combineDateTime(date: day, time: event.startTime),
          endTime: combineDateTime(date: day, time: event.endTime),
          repeatRule: event.repeatRule,
          customWeekdays: event.customWeekdays,
          appIndex: event.appIndex,
          reminders: event.reminders
        )
        matchingEvents.append(repeatedEvent)
      }
    }

    return matchingEvents.sorted { $0.startTime < $1.startTime }
  }

  private func shouldRepeatOn(event: EventTransfer, date: Date) -> Bool {
    let cal = Calendar.current
    let eventDate = event.date
    let targetDate = date

    if targetDate < eventDate {
      return false
    }

    switch event.repeatRule {
    case .none:
      return false
    case .daily:
      return true
    case .weekly:
      let eventWeekday = cal.component(.weekday, from: eventDate)
      let targetWeekday = cal.component(.weekday, from: targetDate)
      return eventWeekday == targetWeekday
    case .weekdays:
      let targetWeekday = cal.component(.weekday, from: targetDate)
      return targetWeekday >= 2 && targetWeekday <= 6
    case .custom:
      let targetWeekday = cal.component(.weekday, from: targetDate)
      return event.customWeekdays.contains(targetWeekday)
    }
  }

  func upcomingEvents(within minutes: Int = 60) -> [EventTransfer] {
    let now = Date()
    let futureDate = Calendar.current.date(byAdding: .minute, value: minutes, to: now) ?? now

    return events.filter { event in
      event.startTime > now && event.startTime <= futureDate
    }.sorted { $0.startTime < $1.startTime }
  }

  private func combineDateTime(date: Date, time: Date) -> Date {
    let calendar = Calendar.current
    let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
    let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

    var combined = DateComponents()
    combined.year = dateComponents.year
    combined.month = dateComponents.month
    combined.day = dateComponents.day
    combined.hour = timeComponents.hour
    combined.minute = timeComponents.minute

    return calendar.date(from: combined) ?? date
  }

  private func saveEvents() {
    guard let data = try? JSONEncoder().encode(events) else { return }
    UserDefaults.standard.set(data, forKey: "watch_calendar_events")
  }

  private func loadEvents() {
    guard let data = UserDefaults.standard.data(forKey: "watch_calendar_events"),
      let decoded = try? JSONDecoder().decode([EventTransfer].self, from: data)
    else {
      return
    }
    events = decoded
  }
}
