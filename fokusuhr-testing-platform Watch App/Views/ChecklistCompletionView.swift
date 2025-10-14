import SwiftUI

struct ChecklistCompletionView: View {
  @Binding var selectedAppIndex: Int?

  var body: some View {
    VStack(spacing: 10) {
      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 60))
        .foregroundColor(.green)

      Text("Super gemacht!")
        .foregroundColor(.white)
        .fontWeight(.bold)

    }
  }
}
