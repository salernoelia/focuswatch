import SwiftUI

enum CalendarViewMode {
    case today
    case week
}

struct CalendarView: View {
    @StateObject private var calendarManager = CalendarViewModel.shared
    @StateObject private var appsManager = AppsManager.shared
    @EnvironmentObject var syncCoordinator: SyncCoordinator
    @State private var viewMode: CalendarViewMode = .today
    @State private var selectedEvent: EventTransfer?

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
        ScrollView {
                VStack(spacing: 8) {
                    if viewMode == .today {
                        todayView
                    } else {
                        weekView
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 6)
                .padding(.bottom, 8)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewMode = viewMode == .today ? .week : .today
                } label: {
                    Text(viewMode == .today ? String(localized: "Week") : String(localized: "Today"))
                        .font(.caption)
                }
            }
        }
        .sheet(item: $selectedEvent) { event in
            NavigationStack {
                CalendarDetailView(event: event, syncCoordinator: syncCoordinator)
            }
        }
        .onAppear {
            appLogger.logViewLifecycle(appName: "kalender", event: "open")
        }
        .onDisappear {
            appLogger.logViewLifecycle(appName: "kalender", event: "close")
        }
    }

    private var todayView: some View {
        Group {
            if todayEvents.isEmpty {
                Text(String(localized: "No events"))
                    .foregroundColor(.secondary)
                    .font(.caption)
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
                Text(String(localized: "No events"))
                    .foregroundColor(.secondary)
                    .font(.caption)
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
        Button {
            selectedEvent = event
        } label: {
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
        .buttonStyle(.plain)
    }

    private func dateHeaderString(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.wide).day().month(.abbreviated))
    }

    private func timeString(_ date: Date) -> String {
        let df = DateFormatter()
        df.timeStyle = .short
        return df.string(from: date)
    }

    private func colorForApp(_ appIndex: Int?) -> Color {
        guard let appIndex = appIndex,
              let app = appsManager.app(forLegacyIndex: appIndex)
        else { return .gray }
        return app.color
    }
}

#Preview {
    CalendarView()
}
