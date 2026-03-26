import SwiftUI

struct LoginRequiredView: View {
  @Binding var showingLoginSheet: Bool

  var body: some View {
    VStack(spacing: 20) {
      Image(systemName: "lock.circle")
        .font(.system(size: 60))
        .foregroundColor(.secondary)

      Text("Login Required")
        .font(.title2)
        .fontWeight(.semibold)

      Text("Please log in to access your journal entries")
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)

      Button("Login") {
        showingLoginSheet = true
      }
      .buttonStyle(.borderedProminent)
      .padding(.top)
    }
    .padding()
    .navigationTitle("Feedback")
    .navigationBarTitleDisplayMode(.large)
  }
}

#Preview {
  LoginRequiredView(showingLoginSheet: .constant(false))
}
