//
//  CalendarRules.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 21.08.2025.
//

import Foundation

enum RepeatRule: String, CaseIterable, Identifiable, Codable {
    case none, daily, weekly, weekdays, custom
    var id: String { rawValue }
}

enum ActivityType: String, CaseIterable, Identifiable, Codable {
    case homework, sports, music, other
    var id: String { rawValue }
}

struct Event: Identifiable, Codable {
    let id: UUID
    var title: String
    var date: Date           // the day
    var startTime: Date
    var endTime: Date
    var repeatRule: RepeatRule
    var customWeekdays: [Int] = []  // 1...7 for Sun…Sat
    var type: ActivityType
    
    init(id: UUID = UUID(), title: String, date: Date, startTime: Date, endTime: Date, repeatRule: RepeatRule, customWeekdays: [Int] = [], type: ActivityType) {
        self.id = id
        self.title = title
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.repeatRule = repeatRule
        self.customWeekdays = customWeekdays
        self.type = type
    }
}
