import SwiftUI

struct CalendarDetailView: View {
  let event: EventTransfer
  @StateObject private var appsManager = AppsManager.shared
  @ObservedObject var watchConnector: WatchConnector
  @Environment(\.dismiss) private var dismiss
  @State private var isLaunching = false

  private var appInfo: AppInfo? {
    guard let appIndex = event.appIndex else { return nil }
    return appsManager.apps.first(where: { $0.index == appIndex })
  }

  private var appTitle: String {
    appInfo?.title ?? String(localized: "No app")
  }

  private var appColor: Color {
    appInfo?.color ?? .gray
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        VStack(alignment: .leading, spacing: 8) {
          Text(event.title)
            .font(.headline)
            .fontWeight(.semibold)

          if let description = event.eventDescription, !description.isEmpty {
            Text(description)
              .font(.caption)
              .foregroundColor(.secondary)
              .padding(.top, 4)
          }

          HStack(spacing: 4) {
            Image(systemName: "clock")
              .font(.caption2)
            Text("\(timeString(event.startTime)) – \(timeString(event.endTime))")
              .font(.caption)
          }
          .foregroundColor(.secondary)

          HStack(spacing: 4) {
            Image(systemName: "calendar")
              .font(.caption2)
            Text(dateString(event.date))
              .font(.caption)
          }
          .foregroundColor(.secondary)
        }

        if event.repeatRule != .none {
          HStack(spacing: 4) {
            Image(systemName: "repeat")
              .font(.caption2)
            Text(repeatRuleText(event.repeatRule))
              .font(.caption)
          }
          .foregroundColor(.secondary)
        }

        if !event.reminders.isEmpty {
          VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
              Image(systemName: "bell.fill")
                .font(.caption2)
              Text(String(localized: "Reminders"))
                .font(.caption)
                .fontWeight(.medium)
            }
            .foregroundColor(.secondary)

            ForEach(event.reminders, id: \.id) { reminder in
              Text(reminderText(reminder))
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.leading, 16)
            }
          }
        }

        if event.appIndex != nil {
          VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
              Image(systemName: "app.fill")
                .font(.caption2)
              Text(String(localized: "Linked App"))
                .font(.caption)
                .fontWeight(.medium)
            }
            .foregroundColor(.secondary)

            HStack(spacing: 8) {
              Circle()
                .fill(appColor)
                .frame(width: 8, height: 8)
              Text(appTitle)
                .font(.caption)
            }
            .padding(.leading, 16)

            Button {
              guard !isLaunching, let appIndex = event.appIndex else { return }
              isLaunching = true
              watchConnector.currentView = .app(appIndex)
              dismiss()
            } label: {
              Text(String(localized: "Start App"))
                .font(.caption)
            }
            .tint(.green)
            .buttonStyle(.borderedProminent)
            .disabled(isLaunching)
          }
        }
      }
      .padding()
    }
    .navigationTitle(String(localized: "Event Details"))
    .navigationBarTitleDisplayMode(.inline)
  }

  private func timeString(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }

  private func dateString(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.locale = Locale(identifier: "de_DE")
    return formatter.string(from: date)
  }

  private func repeatRuleText(_ rule: RepeatRule) -> String {
    switch rule {
    case .none:
      return String(localized: "No repeat")
    case .daily:
      return String(localized: "Daily")
    case .weekly:
      return String(localized: "Weekly")
    case .weekdays:
      return String(localized: "Weekdays")
    case .custom:
      return String(localized: "Custom")
    }
  }

  private func reminderText(_ reminder: Reminder) -> String {
    if reminder.minutesBefore == 0 {
      return String(localized: "At event time")
    } else {
      return String(localized: "\(reminder.minutesBefore) minutes before")
    }
  }
}

#Preview {
  NavigationStack {
    CalendarDetailView(
      event: EventTransfer(
        id: UUID(),
        title: "Mathe Hausaufgaben",
        eventDescription: "Seite 42-45 lösen und Formeln wiederholen",
        date: Date(),
        startTime: Date(),
        endTime: Date().addingTimeInterval(3600),
        repeatRule: .weekly,
        customWeekdays: [],
        appIndex: 0,
        reminders: [Reminder(minutesBefore: 10), Reminder(minutesBefore: 30)]
      ),
      watchConnector: WatchConnector.shared
    )
  }
}
