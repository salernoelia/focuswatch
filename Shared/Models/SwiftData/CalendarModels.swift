import Foundation
import SwiftData

@Model
final class CalendarEventModel {
    var id: UUID
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
    
    init(id: UUID = UUID(), title: String, date: Date, startTime: Date, endTime: Date, repeatRule: RepeatRule, customWeekdays: [Int] = [], type: ActivityType) {
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
