import SwiftUI

enum CalendarViewMode {
  case today
  case week
}

struct CalendarView: View {
  @StateObject private var calendarManager = CalendarManager.shared
  @StateObject private var appsManager = AppsManager.shared
  @State private var viewMode: CalendarViewMode = .today
  
  private let appLogger = AppLogger.shared

  private var todayEvents: [EventTransfer] {
    calendarManager.events(on: Date())
  }

  private var weekEvents: [(date: Date, events: [EventTransfer])] {
    let calendar = Calendar.current
    let today = Date()
    var result: [(date: Date, events: [EventTransfer])] = []

    for i in 0..<7 {
      if let date = calendar.date(byAdding: .day, value: i, to: today) {
        let events = calendarManager.events(on: date)
        if !events.isEmpty {
          result.append((date: date, events: events))
        }
      }
    }
    return result
  }

  var body: some View {
    VStack(spacing: 0) {
      VStack(spacing: 4) {
        HStack(spacing: 0) {
          Button {
            viewMode = .today
          } label: {
            Text("Heute")
              .font(.caption)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 6)
              .background(viewMode == .today ? Color.accentColor : Color.clear)
              .foregroundColor(viewMode == .today ? .white : .primary)
          }
          .buttonStyle(.plain)

          Button {
            viewMode = .week
          } label: {
            Text("Woche")
              .font(.caption)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 6)
              .background(viewMode == .week ? Color.accentColor : Color.clear)
              .foregroundColor(viewMode == .week ? .white : .primary)
          }
          .buttonStyle(.plain)
        }
        .background(Color(.darkGray).opacity(0.3))
        .cornerRadius(8)

        // #if DEBUG
        //   Button {
        //     calendarManager.scheduleTestNotification()
        //   } label: {
        //     Text("Test Notification")
        //       .font(.caption2)
        //       .foregroundColor(.orange)
        //   }
        // #endif
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 4)

      ScrollView {
        VStack(spacing: 8) {
          if viewMode == .today {
            todayView
          } else {
            weekView
          }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
      }
    }
    .navigationTitle("Kalender")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      appLogger.logViewLifecycle(appName: "kalender", event: "opened")
    }
    .onDisappear {
      appLogger.logViewLifecycle(appName: "kalender", event: "closed")
    }
  }

  private var todayView: some View {
    Group {
      if todayEvents.isEmpty {
        VStack(spacing: 8) {
          Image(systemName: "calendar")
            .font(.largeTitle)
            .foregroundColor(.secondary)
          Text("Keine Events")
            .foregroundColor(.secondary)
            .font(.caption)
        }
        .padding()
      } else {
        ForEach(todayEvents, id: \.id) { event in
          eventCard(event)
        }
      }
    }
  }

  private var weekView: some View {
    Group {
      if weekEvents.isEmpty {
        VStack(spacing: 8) {
          Image(systemName: "calendar")
            .font(.largeTitle)
            .foregroundColor(.secondary)
          Text("Keine Events")
            .foregroundColor(.secondary)
            .font(.caption)
        }
        .padding()
      } else {
        ForEach(weekEvents, id: \.date) { dayData in
          VStack(alignment: .leading, spacing: 4) {
            Text(dateHeaderString(dayData.date))
              .font(.caption)
              .fontWeight(.semibold)
              .foregroundColor(.accentColor)
              .padding(.top, 4)

            ForEach(dayData.events, id: \.id) { event in
              eventCard(event)
            }
          }
        }
      }
    }
  }

  private func eventCard(_ event: EventTransfer) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Circle()
          .fill(colorForApp(event.appIndex))
          .frame(width: 6, height: 6)
        Text(event.title)
          .font(.headline)
          .lineLimit(1)
      }

      HStack {
        Text("\(timeString(event.startTime)) – \(timeString(event.endTime))")
          .font(.caption2)
          .foregroundColor(.secondary)
        Spacer()
        HStack(spacing: 4) {
          if event.repeatRule != .none {
            Image(systemName: "repeat")
              .font(.caption2)
              .foregroundColor(.secondary)
          }
          if !event.reminders.isEmpty {
            Image(systemName: "bell.fill")
              .font(.caption2)
              .foregroundColor(.secondary)
          }
          if event.appIndex != nil {
            Image(systemName: "app.fill")
              .font(.caption2)
              .foregroundColor(.secondary)
          }
        }
      }
    }
    .padding(8)
    .background(Color(.darkGray).opacity(0.3))
    .cornerRadius(8)
  }

  private func dateHeaderString(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE, d. MMM"
    formatter.locale = Locale(identifier: "de_DE")
    return formatter.string(from: date)
  }

  private func timeString(_ date: Date) -> String {
    let df = DateFormatter()
    df.timeStyle = .short
    return df.string(from: date)
  }

  private func colorForApp(_ appIndex: Int?) -> Color {
    guard let appIndex = appIndex,
      let app = appsManager.apps.first(where: { $0.index == appIndex })
    else { return .gray }
    return app.color
  }
}

#Preview {
  CalendarView()
}
