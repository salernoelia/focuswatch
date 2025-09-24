import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @State private var showingSuccessMessage = false
    @State private var isLoading = false
    @Environment(\.presentationMode) private var presentationMode
    
    private let authService = AuthService.shared

    var body: some View {
        VStack(spacing: 20) {
            Text("Login")
                .font(.largeTitle)
                .bold()

            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

            SecureField("Password", text: $password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            if showingSuccessMessage {
                Text("Login successful!")
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                Task {
                    await signIn()
                }
            }) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Sign In")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .disabled(isLoading || email.isEmpty || password.isEmpty)
        }
        .padding()
    }

    private func signIn() async {
        errorMessage = nil
        showingSuccessMessage = false
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await authService.signIn(email: email, password: password)
            showingSuccessMessage = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                presentationMode.wrappedValue.dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}


#Preview {
    LoginView()
}
