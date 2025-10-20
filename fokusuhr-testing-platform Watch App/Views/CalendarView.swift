import SwiftUI

struct CalendarView: View {
  @StateObject private var calendarManager = CalendarManager.shared
  @State private var selectedDate = Date()

  private var todayEvents: [EventTransfer] {
    calendarManager.events(on: selectedDate)
  }

  private var dateString: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE, MMM d"
    return formatter.string(from: selectedDate)
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 12) {
        DatePicker("", selection: $selectedDate, displayedComponents: [.date])
          .datePickerStyle(.wheel)
          .labelsHidden()

        if todayEvents.isEmpty {
          Text("No events")
            .foregroundColor(.secondary)
            .font(.caption)
            .padding()
        } else {
          ForEach(todayEvents, id: \.id) { event in
            VStack(alignment: .leading, spacing: 4) {
              HStack {
                Circle()
                  .fill(colorForType(event.type))
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
                if event.repeatRule != .none {
                  Image(systemName: "repeat")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
              }
            }
            .padding(8)
            .background(Color(.darkGray).opacity(0.3))
            .cornerRadius(8)
          }
        }
      }
      .padding(.horizontal, 8)
    }
    .navigationTitle("Calendar")
  }

  private func timeString(_ date: Date) -> String {
    let df = DateFormatter()
    df.timeStyle = .short
    return df.string(from: date)
  }

  private func colorForType(_ type: ActivityType) -> Color {
    switch type {
    case .homework: return .orange
    case .sports: return .green
    case .music: return .purple
    case .other: return .blue
    }
  }
}

#Preview {
  CalendarView()
}
