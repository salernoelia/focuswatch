import SwiftUI

struct CalendarEntryTriggerConsent: View {
  let event: EventTransfer
  let reminder: Reminder
  @StateObject private var appsManager = AppsManager.shared
  @StateObject private var calendarManager = CalendarViewModel.shared
  @Environment(\.dismiss) private var dismiss
  @ObservedObject var watchConnector: WatchConnector
  @State private var isLaunching = false

  private var appTitle: String {
    if let appIndex = event.appIndex,
      let app = appsManager.apps.first(where: { $0.index == appIndex })
    {
      return app.title
    }
    return "this activity"
  }

  var body: some View {
    VStack(spacing: 8) {
      Text(event.title)
        .font(.headline)
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .fixedSize(horizontal: false, vertical: true)

      if let appIndex = event.appIndex {
        #if DEBUG
          Text("App Index: \(appIndex)")
            .font(.caption2)
            .foregroundColor(.orange)
        #endif

        Button("Starten") {
          guard !isLaunching else { return }
          isLaunching = true
          watchConnector.currentView = .app(appIndex)
          dismiss()
        }
        .tint(.green)
        .buttonStyle(.borderedProminent)
        .disabled(isLaunching)
      }

      Button {
        dismiss()
      } label: {
        Text("Später")
      }
      .buttonStyle(.bordered)
      .disabled(isLaunching)
    }
  }
}

#Preview {
  CalendarEntryTriggerConsent(
    event: EventTransfer(
      id: UUID(),
      title: "Mathe Hausaufgaben",
      date: Date(),
      startTime: Date(),
      endTime: Date().addingTimeInterval(3600),
      repeatRule: .none,
      customWeekdays: [],
      appIndex: 0,
      reminders: []
    ),
    reminder: Reminder(minutesBefore: 10),
    watchConnector: WatchConnector.shared
  )
}
