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
            .multilineTextAlignment(.center)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxHeight: 120)
      }
      Button("Weiter") {
        onContinue()
      }
    }
    .padding()
  }
}
