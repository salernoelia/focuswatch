import SwiftUI

struct ChecklistDescriptionView: View {
  let title: String
  let description: String
  let onContinue: () -> Void

  var body: some View {
    VStack(spacing: 16) {
      if !description.isEmpty {
        ScrollView {
          Text(description)
            .font(.caption)
            .multilineTextAlignment(.leading)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .center)
        }
      }
      Button("Weiter") {
        onContinue()
      }
    }
  }
}
