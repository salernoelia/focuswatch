import SwiftUI

struct ChecklistResumePromptView: View {
  let onResume: () -> Void
  let onRestart: () -> Void

  var body: some View {
    VStack(spacing: 16) {
      Text("Fortschritt gefunden")
        .lineLimit(nil)
        .fixedSize(horizontal: false, vertical: true)

      VStack(spacing: 12) {
        Button(action: onResume) {
          Text(String(localized: "Weitermachen"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.green)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)

        Button(action: onRestart) {
          Text(String(localized: "Neu anfangen"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.red)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
      }
    }
    .padding()
  }
}
