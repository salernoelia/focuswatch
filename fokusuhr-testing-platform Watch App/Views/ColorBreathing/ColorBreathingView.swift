import SwiftUI
import WatchKit



struct ColorBreathingView: View {
  @StateObject private var viewModel = ColorBreathingViewModel()
  private let appLogger = AppLogger.shared

  var body: some View {
    ZStack {
      Color.black
        .ignoresSafeArea()

      VStack(spacing: 20) {
        ZStack {
          Circle()
            .fill(
              RadialGradient(
                colors: [
                  .blue.opacity(0.8), .purple.opacity(0.6),
                  .clear,
                ],
                center: .center,
                startRadius: 10,
                endRadius: 80
              )
            )
            .scaleEffect(viewModel.scale)
            .animation(
              .easeInOut(duration: 4)
                .repeatForever(autoreverses: true),
              value: viewModel.scale
            )
        }
        .frame(width: 120, height: 120)

        Text(viewModel.isInhaling ? "Einatmen" : "Ausatmen")
          .font(.caption)
          .foregroundColor(.white.opacity(0.8))
          .animation(.easeInOut(duration: 1), value: viewModel.isInhaling)
      }
    }
    .onAppear {
      viewModel.startBreathing()
      appLogger.logViewLifecycle(appName: "farbatmung", event: "opened")
    }
    .onDisappear {
      viewModel.stopBreathing()
      appLogger.logViewLifecycle(appName: "farbatmung", event: "closed")
    }
  }
}

#Preview {
  ColorBreathingView()
}
