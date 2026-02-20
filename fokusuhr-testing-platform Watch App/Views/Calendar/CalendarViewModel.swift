import Foundation
import UserNotifications

class CalendarViewModel: ObservableObject {
  @Published var events: [EventTransfer] = []
  @Published var pendingReminder:
    (event: EventTransfer, reminder: Reminder, shouldAutoLaunch: Bool)?

  private var lastSyncedHash: Int?

  static let shared = CalendarViewModel()

  private init() {
    loadEvents()
    requestNotificationPermissions()
  }

  func updateEvents(_ newEvents: [EventTransfer]) {
    let newHash = computeEventsHash(newEvents)

    #if DEBUG
      print("📅 CalendarViewModel: updateEvents called")
      print("   → New events count: \(newEvents.count)")
      print("   → Old events count: \(self.events.count)")
      print("   → New hash: \(newHash)")
      print("   → Last hash: \(lastSyncedHash ?? -1)")
      for event in newEvents {
        print("   📝 Event: \(event.title)")
        print("      → Reminders count: \(event.reminders.count)")
        for reminder in event.reminders {
          print("      → Reminder: \(reminder.minutesBefore) min before, launch: \(reminder.shouldLaunchApp)")
        }
      }
    #endif

    if let lastHash = lastSyncedHash, lastHash == newHash {
      #if DEBUG
        print("⏭️ CalendarViewModel: Events unchanged (hash match), skipping schedule")
      #endif
      return
    }

    DispatchQueue.main.async {
      self.events = newEvents
      self.lastSyncedHash = newHash
      self.saveEvents()

      #if DEBUG
        print("💾 CalendarViewModel: Events saved to UserDefaults")
        print("🔔 CalendarViewModel: Starting to schedule reminders...")
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
      hasher.combine(event.eventDescription)
      hasher.combine(event.startTime)
      hasher.combine(event.repeatRule.rawValue)
      hasher.combine(event.reminders.count)
      for reminder in event.reminders {
        hasher.combine(reminder.id)
        hasher.combine(reminder.minutesBefore)
        hasher.combine(reminder.shouldLaunchApp)
        hasher.combine(reminder.message)
      }
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
    content.interruptionLevel = .active

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
          print("Test notification scheduled for 5 seconds from now")
        #endif
      }
    }
  }

  func scheduleAllReminders() {
    #if DEBUG
      print("🗑️ CalendarViewModel: Removing all pending notifications")
    #endif

    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

    let now = Date()
    let futureEvents = events.filter { event in
      event.startTime > now || event.repeatRule != .none
    }

    #if DEBUG
      print("🔄 CalendarViewModel: Scheduling reminders for \(futureEvents.count) future/repeating events (filtered from \(events.count) total)")
    #endif

    scheduleUpcomingReminders(for: futureEvents, from: now)

    #if DEBUG
      UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
        print("CalendarViewModel: Total pending notifications: \(requests.count)")
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

  private func scheduleUpcomingReminders(for events: [EventTransfer], from startDate: Date) {
    let calendar = Calendar.current
    let maxLookAhead = calendar.date(byAdding: .day, value: 7, to: startDate) ?? startDate
    let maxNotifications = 60
    
    var scheduledCount = 0
    var reminderDates: [(event: EventTransfer, reminder: Reminder, triggerDate: Date)] = []
    
    for event in events {
      if event.repeatRule == .none {
        for reminder in event.reminders {
          if let triggerDate = calendar.date(byAdding: .minute, value: -reminder.minutesBefore, to: event.startTime),
             triggerDate > startDate {
            reminderDates.append((event: event, reminder: reminder, triggerDate: triggerDate))
          }
        }
      } else {
        var currentDate = startDate
        while currentDate <= maxLookAhead {
          if shouldRepeatOn(event: event, date: currentDate) {
            let occurrenceTime = combineDateTime(date: currentDate, time: event.startTime)
            
            for reminder in event.reminders {
              if let triggerDate = calendar.date(byAdding: .minute, value: -reminder.minutesBefore, to: occurrenceTime),
                 triggerDate > startDate {
                reminderDates.append((event: event, reminder: reminder, triggerDate: triggerDate))
              }
            }
          }
          
          guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
          currentDate = nextDate
        }
      }
    }
    
    reminderDates.sort { $0.triggerDate < $1.triggerDate }
    
    for reminderInfo in reminderDates.prefix(maxNotifications) {
      scheduleReminder(
        for: reminderInfo.event,
        reminder: reminderInfo.reminder,
        at: reminderInfo.triggerDate
      )
      scheduledCount += 1
    }
    
    #if DEBUG
      print("📊 Scheduled \(scheduledCount) notifications (\(reminderDates.count) total candidates)")
    #endif
  }

  private func shouldRepeatOn(event: EventTransfer, date: Date) -> Bool {
    let cal = Calendar.current
    let eventDate = event.date
    
    if date < cal.startOfDay(for: eventDate) {
      return false
    }
    
    switch event.repeatRule {
    case .none:
      return false
    case .daily:
      return true
    case .weekly:
      let eventWeekday = cal.component(.weekday, from: eventDate)
      let targetWeekday = cal.component(.weekday, from: date)
      return eventWeekday == targetWeekday
    case .weekdays:
      let targetWeekday = cal.component(.weekday, from: date)
      return targetWeekday >= 2 && targetWeekday <= 6
    case .custom:
      let targetWeekday = cal.component(.weekday, from: date)
      return event.customWeekdays.contains(targetWeekday)
    }
  }
  
  private func combineDateTime(date: Date, time: Date) -> Date {
    let calendar = Calendar.current
    let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
    let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
    
    var combined = DateComponents()
    combined.year = dateComponents.year
    combined.month = dateComponents.month
    combined.day = dateComponents.day
    combined.hour = timeComponents.hour
    combined.minute = timeComponents.minute
    combined.second = timeComponents.second
    
    return calendar.date(from: combined) ?? date
  }

  private func scheduleReminders(for event: EventTransfer) {
    for reminder in event.reminders {
      scheduleReminder(for: event, reminder: reminder)
    }
  }

  private func scheduleReminder(for event: EventTransfer, reminder: Reminder, at triggerDate: Date? = nil) {
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
    content.interruptionLevel = .timeSensitive
    content.userInfo = [
      "eventId": event.id.uuidString,
      "reminderId": reminder.id.uuidString,
      "appIndex": event.appIndex as Any,
      "shouldLaunchApp": reminder.shouldLaunchApp,
    ]

    if reminder.shouldLaunchApp && event.appIndex != nil {
      content.categoryIdentifier = "CALENDAR_REMINDER_LAUNCH"
    } else {
      content.categoryIdentifier = "CALENDAR_REMINDER"
    }

    let calculatedTriggerDate: Date
    if let explicitDate = triggerDate {
      calculatedTriggerDate = explicitDate
    } else {
      guard let computed = Calendar.current.date(
        byAdding: .minute, value: -reminder.minutesBefore, to: event.startTime) else {
        #if DEBUG
          print("❌ Failed to calculate trigger date for \(event.title)")
        #endif
        return
      }
      calculatedTriggerDate = computed
    }

    let now = Date()

    #if DEBUG
      let formatter = DateFormatter()
      formatter.dateStyle = .short
      formatter.timeStyle = .short
      print("⏰ Scheduling: \(event.title)")
      print("   → Event start: \(formatter.string(from: event.startTime))")
      print("   → Reminder: \(reminder.minutesBefore) min before")
      print("   → Trigger date: \(formatter.string(from: calculatedTriggerDate))")
      print("   → Current time: \(formatter.string(from: now))")
    #endif

    guard calculatedTriggerDate > now else {
      #if DEBUG
        print("⏭️ SKIPPED: Trigger date is in the past")
        print("   → Event: \(event.title)")
        print("   → Trigger was: \(calculatedTriggerDate)")
        print("   → Now is: \(now)")
      #endif
      return
    }

    let components = Calendar.current.dateComponents(
      [.year, .month, .day, .hour, .minute, .second], from: calculatedTriggerDate)
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

    let identifier = "\(event.id.uuidString)-\(reminder.id.uuidString)-\(calculatedTriggerDate.timeIntervalSince1970)"
    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

    UNUserNotificationCenter.current().add(request) { error in
      if let error = error {
        #if DEBUG
          print("❌ Failed to schedule reminder for \(event.title): \(error)")
          ErrorLogger.log("Failed to schedule reminder: \(error)")
        #endif
      } else {
        #if DEBUG
          print("Successfully scheduled reminder for \(event.title)")
        #endif
      }
    }
  }

  func handleReminderResponse(eventId: UUID, reminderId: UUID, shouldLaunch: Bool) {
    guard let event = events.first(where: { $0.id == eventId }),
      let reminder = event.reminders.first(where: { $0.id == reminderId })
    else { return }

    pendingReminder = (event, reminder, shouldLaunch)
  }
  
  func rescheduleIfNeeded() async {
    let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
    
    if requests.isEmpty && !self.events.isEmpty {
      #if DEBUG
        print("⚠️ No pending notifications but have events - rescheduling")
      #endif
      DispatchQueue.main.async {
        self.scheduleAllReminders()
      }
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
          eventDescription: event.eventDescription,
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
