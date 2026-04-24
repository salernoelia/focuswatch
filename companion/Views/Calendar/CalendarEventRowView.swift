import SwiftUI

struct CalendarEventRowView: View {
  let event: Event
  @StateObject private var appsManager = AppsManager.shared

  private var appColor: Color {
    if let appIndex = event.appIndex,
      let app = appsManager.apps.first(where: { $0.legacyIndex == appIndex })
    {
      return app.color
    }
    return .gray
  }

  private var appTitle: String? {
    if let appIndex = event.appIndex,
      let app = appsManager.apps.first(where: { $0.legacyIndex == appIndex })
    {
      return app.title
    }
    return nil
  }

  var body: some View {
    HStack(spacing: 12) {
      RoundedRectangle(cornerRadius: 2)
        .fill(appColor)
        .frame(width: 4, height: 44)

      VStack(alignment: .leading, spacing: 4) {
        Text(event.title)
          .font(.headline)
          .lineLimit(1)

        HStack(spacing: 4) {
          if let appTitle = appTitle {
            Text(appTitle)
              .font(.caption)
              .padding(.horizontal, 8)
              .padding(.vertical, 2)
              .background(appColor.opacity(0.15))
              .foregroundColor(appColor)
              .cornerRadius(8)
          }

          if event.repeatRule != .none {
            Image(systemName: "repeat")
              .font(.caption)
              .foregroundColor(.secondary)
          }

          if !event.reminders.isEmpty {
            Image(systemName: "bell.fill")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
      }

      Spacer()

      VStack(alignment: .trailing, spacing: 2) {
        Text("\(timeString(event.startTime)) – \(timeString(event.endTime))")
          .font(.subheadline)
          .fontWeight(.medium)

        if event.repeatRule != .none {
          Text(event.repeatRule.rawValue.capitalized)
            .font(.caption2)
            .foregroundColor(.secondary)
        }
      }
    }
    .padding(.vertical, 4)
  }

  private func timeString(_ date: Date) -> String {
    let df = DateFormatter()
    df.timeStyle = .short
    return df.string(from: date)
  }
}
