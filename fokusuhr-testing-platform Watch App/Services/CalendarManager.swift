import Foundation

class CalendarManager: ObservableObject {
  @Published var events: [EventTransfer] = []

  static let shared = CalendarManager()

  private init() {
    loadEvents()
  }

  func updateEvents(_ newEvents: [EventTransfer]) {
    events = newEvents
    saveEvents()
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
          type: event.type
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
