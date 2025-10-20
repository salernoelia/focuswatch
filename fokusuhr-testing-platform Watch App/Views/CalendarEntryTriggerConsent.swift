import SwiftUI

struct CalendarEntryTriggerConsent: View {
  let event: EventTransfer
  let reminder: Reminder
  @StateObject private var appsManager = AppsManager.shared
  @StateObject private var calendarManager = CalendarManager.shared
  @Environment(\.dismiss) private var dismiss
  @ObservedObject var watchConnector: WatchConnector

  private var appTitle: String {
    if let appIndex = event.appIndex,
      let app = appsManager.apps.first(where: { $0.index == appIndex })
    {
      return app.title
    }
    return "this activity"
  }

  var body: some View {
    VStack(spacing: 20) {
      Spacer()

      VStack(spacing: 8) {
        Image(systemName: "calendar.badge.clock")
          .font(.system(size: 40))
          .foregroundColor(.accentColor)

        Text("Ready for")
          .font(.headline)

        Text(event.title)
          .font(.title2)
          .fontWeight(.bold)
          .multilineTextAlignment(.center)

        if event.appIndex != nil {
          Text("Launch \(appTitle)?")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
      }

      Spacer()

      VStack(spacing: 12) {
        if event.appIndex != nil && reminder.shouldLaunchApp {
          Button {
            if let appIndex = event.appIndex {
              watchConnector.currentView = .app(appIndex)
            }
            dismiss()
          } label: {
            HStack {
              Image(systemName: "play.circle.fill")
              Text("Launch")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
          }
          .buttonStyle(.borderedProminent)
        }

        Button {
          dismiss()
        } label: {
          HStack {
            Image(systemName: event.appIndex != nil ? "xmark.circle" : "checkmark.circle")
            Text(event.appIndex != nil ? "Not Now" : "OK")
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
        }
        .buttonStyle(.bordered)
      }
      .padding(.horizontal)
    }
    .padding()
  }
}

#Preview {
  CalendarEntryTriggerConsent(
    event: EventTransfer(
      id: UUID(),
      title: "Math Homework",
      date: Date(),
      startTime: Date(),
      endTime: Date().addingTimeInterval(3600),
      repeatRule: .none,
      customWeekdays: [],
      appIndex: 0,
      reminders: []
    ),
    reminder: Reminder(minutesBefore: 10),
    watchConnector: WatchConnector()
  )
}
