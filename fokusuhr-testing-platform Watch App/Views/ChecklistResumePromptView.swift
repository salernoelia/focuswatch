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
          Text("Weitermachen")
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.green)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)

        Button(action: onRestart) {
          Text("Neu anfangen")
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.orange)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
      }
    }
    .padding()
  }
}
