import SwiftUI

struct ChecklistInstructionsView: View {
  let title: String
  let onStart: () -> Void

  var body: some View {
    VStack(spacing: 16) {
      HStack {
        Text(title)
          .font(.headline)
          .fontWeight(.bold)
        Spacer()
      }
      VStack(spacing: 12) {
        HStack(spacing: 8) {
          Image(systemName: "arrow.right")
            .foregroundColor(.green)
          Text("Rechts = Hab ich!")
            .font(.caption2)
        }

        HStack(spacing: 8) {
          Image(systemName: "arrow.left")
            .foregroundColor(.orange)
          Text("Links = Später")
            .font(.caption2)
        }
      }

      Button("Loslegen") {
        onStart()
      }
    }
    .padding()
  }
}
