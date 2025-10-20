import Foundation
import UserNotifications

class CalendarManager: ObservableObject {
  @Published var events: [EventTransfer] = []
  @Published var pendingReminder: (event: EventTransfer, reminder: Reminder)?

  private var lastSyncedHash: Int?

  static let shared = CalendarManager()

  private init() {
    loadEvents()
    requestNotificationPermissions()
  }

  func updateEvents(_ newEvents: [EventTransfer]) {
    let newHash = computeEventsHash(newEvents)

    #if DEBUG
      print("📅 CalendarManager: updateEvents called")
      print("   → New events count: \(newEvents.count)")
      print("   → Old events count: \(self.events.count)")
      print("   → New hash: \(newHash)")
      print("   → Last hash: \(lastSyncedHash ?? -1)")
    #endif

    if let lastHash = lastSyncedHash, lastHash == newHash {
      #if DEBUG
        print("⏭️ CalendarManager: Events unchanged (hash match), skipping schedule")
      #endif
      return
    }

    DispatchQueue.main.async {
      self.events = newEvents
      self.lastSyncedHash = newHash
      self.saveEvents()

      #if DEBUG
        print("💾 CalendarManager: Events saved to UserDefaults")
        print("🔔 CalendarManager: Starting to schedule reminders...")
      #endif

      self.scheduleAllReminders()
    }
  }

  private func computeEventsHash(_ events: [EventTransfer]) -> Int {
    var hasher = Hasher()
    hasher.combine(events.count)
    for event in events {
      hasher.combine(event.id)
      hasher.combine(event.title)
      hasher.combine(event.startTime)
      hasher.combine(event.reminders.count)
    }
    return hasher.finalize()
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
    #if DEBUG
      print("🗑️ CalendarManager: Removing all pending notifications")
    #endif

    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

    #if DEBUG
      print("🔄 CalendarManager: Scheduling reminders for \(events.count) events")
    #endif

    for event in events {
      scheduleReminders(for: event)
    }

    #if DEBUG
      UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
        print("✅ CalendarManager: Total pending notifications: \(requests.count)")
        for request in requests {
          if let trigger = request.trigger as? UNCalendarNotificationTrigger,
            let nextTriggerDate = trigger.nextTriggerDate()
          {
            print("   → \(request.content.title) at \(nextTriggerDate)")
          }
        }
      }
    #endif
  }

  private func scheduleReminders(for event: EventTransfer) {
    for reminder in event.reminders {
      scheduleReminder(for: event, reminder: reminder)
    }
  }

  private func scheduleReminder(for event: EventTransfer, reminder: Reminder) {
    let content = UNMutableNotificationContent()
    content.title = event.title

    if let message = reminder.message, !message.isEmpty {
      content.body = message
    } else if reminder.minutesBefore == 0 {
      content.body = "Beginnt jetzt"
    } else {
      content.body = "Beginnt in \(reminder.minutesBefore) Minuten"
    }

    content.sound = .default
    content.userInfo = [
      "eventId": event.id.uuidString,
      "reminderId": reminder.id.uuidString,
      "appIndex": event.appIndex as Any,
      "shouldLaunchApp": reminder.shouldLaunchApp,
    ]

    let triggerDate = Calendar.current.date(
      byAdding: .minute, value: -reminder.minutesBefore, to: event.startTime)

    guard let triggerDate = triggerDate else {
      #if DEBUG
        print("❌ Failed to calculate trigger date for \(event.title)")
      #endif
      return
    }

    let now = Date()

    #if DEBUG
      let formatter = DateFormatter()
      formatter.dateStyle = .short
      formatter.timeStyle = .short
      print("⏰ Scheduling: \(event.title)")
      print("   → Event start: \(formatter.string(from: event.startTime))")
      print("   → Reminder: \(reminder.minutesBefore) min before")
      print("   → Trigger date: \(formatter.string(from: triggerDate))")
      print("   → Current time: \(formatter.string(from: now))")
    #endif

    guard triggerDate > now else {
      #if DEBUG
        print("⏭️ SKIPPED: Trigger date is in the past")
        print("   → Event: \(event.title)")
        print("   → Trigger was: \(triggerDate)")
        print("   → Now is: \(now)")
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
          print("❌ Failed to schedule reminder for \(event.title): \(error)")
          ErrorLogger.log("Failed to schedule reminder: \(error)")
        #endif
      } else {
        #if DEBUG
          print("✅ Successfully scheduled reminder for \(event.title)")
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
