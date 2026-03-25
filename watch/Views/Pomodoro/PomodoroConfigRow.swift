import SwiftUI
import UserNotifications
import WatchKit

struct PomodoroConfigRow: View {
  let title: String
  @Binding var value: Int
  let range: ClosedRange<Int>
  let unit: String

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(.caption)
        .foregroundStyle(.secondary)

      HStack {
        Button {
          if value > range.lowerBound {
            value -= 1
          }
        } label: {
          Image(systemName: "minus.circle.fill")
            .font(.title3)
        }
        .buttonStyle(.plain)
        .disabled(value <= range.lowerBound)

        Spacer()

        Text("\(value) \(unit)")
          .font(.body)
          .monospacedDigit()

        Spacer()

        Button {
          if value < range.upperBound {
            value += 1
          }
        } label: {
          Image(systemName: "plus.circle.fill")
            .font(.title3)
        }
        .buttonStyle(.plain)
        .disabled(value >= range.upperBound)
      }
    }
    .padding(.vertical, 4)
  }
}
