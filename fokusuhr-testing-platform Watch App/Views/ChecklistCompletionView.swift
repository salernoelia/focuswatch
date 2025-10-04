import SwiftUI

struct ChecklistCompletionView: View {
    @Environment(\.presentationMode) private var presentationMode
    @Binding var selectedAppIndex: Int?

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Super gemacht!")
                .foregroundColor(.white)
                .fontWeight(.bold)
            
            Text("Alles gesammelt.")
                .foregroundColor(.white)

            Button(action: {
                selectedAppIndex = nil
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Zurück")
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .cornerRadius(8)
            }
        }
    }
}
