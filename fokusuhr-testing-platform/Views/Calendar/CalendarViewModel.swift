import Combine
import SwiftData
import SwiftUI

@MainActor
class CalendarViewModel: ObservableObject {
  @Published var visibleMonth: Date = Date()
  @Published var lastError: AppError?

  private let modelContext: ModelContext
  private let watchConnector = WatchConnector.shared

  init(modelContext: ModelContext) {
    self.modelContext = modelContext
  }

  func events(on day: Date) -> [Event] {
    let cal = Calendar.current
    let descriptor = FetchDescriptor<Event>()

    guard let allEvents = try? modelContext.fetch(descriptor) else {
      return []
    }

    var matchingEvents: [Event] = []

    for event in allEvents {
      if cal.isDate(event.date, inSameDayAs: day) {
        matchingEvents.append(event)
      } else if event.repeatRule != .none && shouldRepeatOn(event: event, date: day) {
        let repeatedEvent = Event(
          id: UUID(),
          title: event.title,
          date: day,
          startTime: combineDateTime(date: day, time: event.startTime),
          endTime: combineDateTime(date: day, time: event.endTime),
          repeatRule: event.repeatRule,
          customWeekdays: event.customWeekdays,
          appIndex: event.appIndex,
          reminders: event.reminders,
          sourceEventId: event.id
        )
        matchingEvents.append(repeatedEvent)
      }
    }

    return matchingEvents
  }

  private func shouldRepeatOn(event: Event, date: Date) -> Bool {
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

  func add(_ event: Event) {
    modelContext.insert(event)
    save()
  }

  func update(
    eventId: UUID, title: String, date: Date, startTime: Date, endTime: Date,
    repeatRule: RepeatRule, customWeekdays: [Int], appIndex: Int?, reminders: [Reminder]
  ) {
    #if DEBUG
      print("🔍 CalendarViewModel.update called with eventId: \(eventId)")
    #endif

    var descriptor = FetchDescriptor<Event>()
    descriptor.predicate = #Predicate<Event> { event in
      event.id == eventId
    }

    guard let events = try? modelContext.fetch(descriptor) else {
      #if DEBUG
        print("❌ Failed to fetch events")
      #endif
      return
    }

    #if DEBUG
      print("📊 Found \(events.count) events matching ID")
      if events.isEmpty {
        print("❌ NO EVENT FOUND - this will fail silently!")
      }
    #endif

    guard let event = events.first else {
      #if DEBUG
        print("❌ Event not found! Creating new event instead")
      #endif
      let newEvent = Event(
        title: title,
        date: date,
        startTime: startTime,
        endTime: endTime,
        repeatRule: repeatRule,
        customWeekdays: customWeekdays,
        appIndex: appIndex,
        reminders: reminders
      )
      modelContext.insert(newEvent)
      save()
      return
    }

    #if DEBUG
      print("✅ Found event to update: \(event.title)")
    #endif

    event.title = title
    event.date = date
    event.startTime = startTime
    event.endTime = endTime
    event.repeatRule = repeatRule
    event.customWeekdays = customWeekdays
    event.appIndex = appIndex
    event.reminders = reminders

    save()
  }

  func delete(_ event: Event) {
    let id = event.sourceEventId ?? event.id
    var descriptor = FetchDescriptor<Event>()
    descriptor.predicate = #Predicate<Event> { event in
      event.id == id
    }

    guard let events = try? modelContext.fetch(descriptor),
      let eventToDelete = events.first
    else {
      return
    }

    modelContext.delete(eventToDelete)
    save()
  }

  private func save() {
    do {
      try modelContext.save()
      Task { @MainActor in
        syncToWatch()
      }
    } catch {
      let appError = AppError.encodingFailed(type: "calendar events", underlying: error)
      #if DEBUG
        ErrorLogger.log(appError)
      #endif
      lastError = appError
    }
  }

  private func syncToWatch() {
    watchConnector.syncCalendarToWatch()
  }

  func daysInMonth() -> [Date] {
    let cal = Calendar.current
    guard let monthRange = cal.range(of: .day, in: .month, for: visibleMonth),
      let firstOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: visibleMonth))
    else { return [] }
    return monthRange.compactMap { day -> Date? in
      cal.date(byAdding: .day, value: day - 1, to: firstOfMonth)
    }
  }
}
