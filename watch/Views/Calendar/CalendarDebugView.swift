import SwiftUI
import UserNotifications

struct CalendarDebugView: View {
    @StateObject private var calendarManager = CalendarViewModel.shared
    @State private var pendingNotifications: [UNNotificationRequest] = []
    @State private var testResults: [String] = []
    
    var body: some View {
        List {
            Section("Test Results") {
                if testResults.isEmpty {
                    Text("No results yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(testResults.indices, id: \.self) { index in
                        Text(testResults[index])
                            .font(.caption2)
                    }
                }
            }
            
            Section("Actions") {
                Button("Refresh Notifications") {
                    refreshPendingNotifications()
                }
                
                Button("Test Immediate Notification") {
                    testImmediateNotification()
                }
                
                Button("Validate Sync Data") {
                    validateSyncData()
                }
                
                Button("Force Reschedule All") {
                    calendarManager.scheduleAllReminders()
                    testResults.append("[\(Date().formatted(date: .omitted, time: .standard))] Forced reschedule")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        refreshPendingNotifications()
                    }
                }
            }
        }
        .navigationTitle("Calendar Debug")
        .onAppear {
            refreshPendingNotifications()
            validateSyncData()
        }
    }
    
    private func refreshPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                self.pendingNotifications = requests.sorted {
                    guard let trigger1 = $0.trigger as? UNCalendarNotificationTrigger,
                          let trigger2 = $1.trigger as? UNCalendarNotificationTrigger,
                          let date1 = trigger1.nextTriggerDate(),
                          let date2 = trigger2.nextTriggerDate() else {
                        return false
                    }
                    return date1 < date2
                }
            }
        }
    }
    
    private func testImmediateNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This notification should appear in 3 seconds"
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(identifier: "test-\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    testResults.append("[\(Date().formatted(date: .omitted, time: .standard))] ❌ Test failed: \(error.localizedDescription)")
                } else {
                    testResults.append("[\(Date().formatted(date: .omitted, time: .standard))] ✅ Test notification scheduled for 3s")
                }
            }
        }
    }
    
    private func validateSyncData() {
        testResults.removeAll()
        testResults.append("[\(Date().formatted(date: .omitted, time: .standard))] === Validation Started ===")
        testResults.append("Events count: \(calendarManager.events.count)")
        
        let now = Date()
        for event in calendarManager.events {
            testResults.append("Event: \(event.title)")
            testResults.append("  Start: \(event.startTime.formatted(date: .numeric, time: .shortened))")
            testResults.append("  Reminders: \(event.reminders.count)")
            
            for reminder in event.reminders {
                if let triggerDate = Calendar.current.date(byAdding: .minute, value: -reminder.minutesBefore, to: event.startTime) {
                    let isPast = triggerDate <= now
                    let status = isPast ? "⏭️ PAST" : "✅ FUTURE"
                    testResults.append("  • \(reminder.minutesBefore)min → \(status)")
                    testResults.append("    Trigger: \(triggerDate.formatted(date: .omitted, time: .shortened))")
                }
            }
        }
        
        testResults.append("[\(Date().formatted(date: .omitted, time: .standard))] === Validation Complete ===")
    }
}
