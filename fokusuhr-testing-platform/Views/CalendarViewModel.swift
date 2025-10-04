import SwiftUI
import Combine

class CalendarViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var visibleMonth: Date = Date()
    
    private let eventsKey = "calendar_events"
    
    init() {
        loadEvents()
    }
    
    func events(on day: Date) -> [Event] {
        let cal = Calendar.current
        var matchingEvents: [Event] = []
        
        for event in events {
            if cal.isDate(event.date, inSameDayAs: day) {
                matchingEvents.append(event)
            }
            else if event.repeatRule != .none && shouldRepeatOn(event: event, date: day) {
                var repeatedEvent = event
                repeatedEvent.date = day
                repeatedEvent.startTime = combineDateTime(date: day, time: event.startTime)
                repeatedEvent.endTime = combineDateTime(date: day, time: event.endTime)
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
        events.append(event)
        saveEvents()
        objectWillChange.send()
    }
    
    func update(eventId: UUID, title: String, date: Date, startTime: Date, endTime: Date, repeatRule: RepeatRule, customWeekdays: [Int], type: ActivityType) {
        if let index = events.firstIndex(where: { $0.id == eventId }) {
            events[index] = Event(
                id: eventId,
                title: title,
                date: date,
                startTime: startTime,
                endTime: endTime,
                repeatRule: repeatRule,
                customWeekdays: customWeekdays,
                type: type
            )
            saveEvents()
            objectWillChange.send()
        }
    }
    
    func delete(_ event: Event) {
        events.removeAll { $0.id == event.id }
        saveEvents()
        objectWillChange.send()
    }
    
    private func saveEvents() {
        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(encoded, forKey: eventsKey)
        }
    }
    
    private func loadEvents() {
        if let data = UserDefaults.standard.data(forKey: eventsKey),
           let decoded = try? JSONDecoder().decode([Event].self, from: data) {
            events = decoded
        }
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
