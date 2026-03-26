import SwiftUI

struct JournalHistoryEntryRow: View {
  let entry: PublicSchema.JournalsSelect

  private var formattedDate: String {
    guard let createdAt = entry.createdAt else { return "Unknown date" }

    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

    guard let date = formatter.date(from: createdAt) else {
      return createdAt
    }

    let displayFormatter = DateFormatter()
    displayFormatter.dateStyle = .medium
    displayFormatter.timeStyle = .short
    return displayFormatter.string(from: date)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        HStack(spacing: 8) {
          Image(systemName: "app.badge")
            .foregroundColor(.blue)
          Text(entry.appName ?? "not found")
            .font(.headline)
            .foregroundColor(.primary)
        }

        Spacer()

        Text(formattedDate)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      HStack(spacing: 8) {
        Image(systemName: "person.circle")
          .foregroundColor(.green)
        Text("Test User ID: \(entry.testUserId ?? 0)")
          .font(.subheadline)
          .foregroundColor(.secondary)
      }

      Text(entry.description ?? "")
        .font(.body)
        .lineLimit(4)
        .padding(.vertical, 4)
    }
    .padding(.vertical, 4)
  }
}
