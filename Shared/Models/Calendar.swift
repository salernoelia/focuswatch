import Foundation
import SwiftData

enum RepeatRule: String, CaseIterable, Identifiable, Codable {
  case none, daily, weekly, weekdays, custom
  var id: String { rawValue }
}

enum ActivityType: String, CaseIterable, Identifiable, Codable {
  case homework, sports, music, other
  var id: String { rawValue }
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
  var typeRaw: String

  var repeatRule: RepeatRule {
    get { RepeatRule(rawValue: repeatRuleRaw) ?? .none }
    set { repeatRuleRaw = newValue.rawValue }
  }

  var type: ActivityType {
    get { ActivityType(rawValue: typeRaw) ?? .other }
    set { typeRaw = newValue.rawValue }
  }

  init(
    id: UUID = UUID(), title: String, date: Date, startTime: Date, endTime: Date,
    repeatRule: RepeatRule, customWeekdays: [Int] = [], type: ActivityType
  ) {
    self.id = id
    self.title = title
    self.date = date
    self.startTime = startTime
    self.endTime = endTime
    self.repeatRuleRaw = repeatRule.rawValue
    self.customWeekdays = customWeekdays
    self.typeRaw = type.rawValue
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
  let type: ActivityType

  init(
    id: UUID, title: String, date: Date, startTime: Date, endTime: Date, repeatRule: RepeatRule,
    customWeekdays: [Int], type: ActivityType
  ) {
    self.id = id
    self.title = title
    self.date = date
    self.startTime = startTime
    self.endTime = endTime
    self.repeatRule = repeatRule
    self.customWeekdays = customWeekdays
    self.type = type
  }

  init(from event: Event) {
    self.id = event.id
    self.title = event.title
    self.date = event.date
    self.startTime = event.startTime
    self.endTime = event.endTime
    self.repeatRule = event.repeatRule
    self.customWeekdays = event.customWeekdays
    self.type = event.type
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
      type: type
    )
  }
}
