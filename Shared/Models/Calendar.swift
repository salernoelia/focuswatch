import Foundation
import SwiftData

enum RepeatRule: String, CaseIterable, Identifiable, Codable {
  case none, daily, weekly, weekdays, custom
  var id: String { rawValue }
}

struct Reminder: Codable, Identifiable {
  let id: UUID
  var minutesBefore: Int
  var shouldLaunchApp: Bool
  var message: String?

  init(id: UUID = UUID(), minutesBefore: Int, shouldLaunchApp: Bool = true, message: String? = nil)
  {
    self.id = id
    self.minutesBefore = minutesBefore
    self.shouldLaunchApp = shouldLaunchApp
    self.message = message
  }
}

@Model
final class Event {
  @Attribute(.unique) var id: UUID
  var title: String
  var date: Date
  var startTime: Date
  var endTime: Date
  var repeatRuleRaw: String
  var customWeekdays: [Int]
  var appIndex: Int?
  var remindersData: Data?
  var sourceEventId: UUID?

  var repeatRule: RepeatRule {
    get { RepeatRule(rawValue: repeatRuleRaw) ?? .none }
    set { repeatRuleRaw = newValue.rawValue }
  }

  var reminders: [Reminder] {
    get {
      guard let data = remindersData,
        let decoded = try? JSONDecoder().8code([Reminder].self, from: data)
      else { return [] }
      return decoded
    }
    set {
      remindersData = try? JSONEncoder().encode(newValue)
    }
  }

  init(
    id: UUID = UUID(), title: String, date: Date, startTime: Date, endTime: Date,
    repeatRule: RepeatRule, customWeekdays: [Int] = [], appIndex: Int? = nil,
    reminders: [Reminder] = [], sourceEventId: UUID? = nil
  ) {
    self.id = id
    self.title = title
    self.date = date
    self.startTime = startTime
    self.endTime = endTime
    self.repeatRuleRaw = repeatRule.rawValue
    self.customWeekdays = customWeekdays
    self.appIndex = appIndex
    self.remindersData = try? JSONEncoder().encode(reminders)
    self.sourceEventId = sourceEventId
  }
}
struct EventTransfer: Codable {
  let id: UUID
  let title: String
  let date: Date
  let startTime: Date
  let endTime: Date
  let repeatRule: RepeatRule
  let customWeekdays: [Int]
  let appIndex: Int?
  let reminders: [Reminder]

  init(
    id: UUID, title: String, date: Date, startTime: Date, endTime: Date, repeatRule: RepeatRule,
    customWeekdays: [Int], appIndex: Int? = nil, reminders: [Reminder] = []
  ) {
    self.id = id
    self.title = title
    self.date = date
    self.startTime = startTime
    self.endTime = endTime
    self.repeatRule = repeatRule
    self.customWeekdays = customWeekdays
    self.appIndex = appIndex
    self.reminders = reminders
  }

  init(from event: Event) {
    self.id = event.id
    self.title = event.title
    self.date = event.date
    self.startTime = event.startTime
    self.endTime = event.endTime
    self.repeatRule = event.repeatRule
    self.customWeekdays = event.customWeekdays
    self.appIndex = event.appIndex
    self.reminders = event.reminders
  }

  func toEvent() -> Event {
    Event(
      id: id,
      title: title,
      date: date,
      startTime: startTime,
      endTime: endTime,
      repeatRule: repeatRule,
      customWeekdays: customWeekdays,
      appIndex: appIndex,
      reminders: reminders
    )
  }
}
