import SwiftUI

struct ColorBreathingView: View {
    @State private var scale: CGFloat = 0.5
    @State private var isInhaling = true
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.blue.opacity(0.8), .purple.opacity(0.6), .clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 80
                            )
                        )
                        .scaleEffect(scale)
                        .animation(
                            .easeInOut(duration: 4)
                            .repeatForever(autoreverses: true),
                            value: scale
                        )
                    
                }
                .frame(width: 120, height: 120)
                
                Text(isInhaling ? "Einatmen" : "Ausatmen")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .animation(.easeInOut(duration: 4), value: isInhaling)
            }
        }
        .onAppear {
            scale = 1.2
            
            Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
                isInhaling.toggle()
            }
        }
    }
}

#Preview {
    ColorBreathingView()
}
