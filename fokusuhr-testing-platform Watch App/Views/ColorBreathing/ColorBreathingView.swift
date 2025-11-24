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
              .easeInOut(duration: Double(viewModel.configuration.inhaleSeconds))
                .repeatForever(autoreverses: true),
              value: viewModel.scale
            )
        }
        .frame(width: 120, height: 120)

        VStack(spacing: 4) {
          Text(viewModel.isInhaling ? "Einatmen" : "Ausatmen")
            .font(.caption)
            .foregroundColor(.white.opacity(0.8))
            .animation(.easeInOut(duration: 1), value: viewModel.isInhaling)

          if viewModel.configuration.cycleCount > 0 {
            Text("\(viewModel.currentCycle) / \(viewModel.configuration.cycleCount)")
              .font(.caption2)
              .foregroundColor(.white.opacity(0.5))
          }
        }
      }
    }
    .onAppear {
      viewModel.startBreathing()
      appLogger.logViewLifecycle(appName: "farbatmung", event: "open")
    }
    .onDisappear {
      viewModel.stopBreathing()
      appLogger.logViewLifecycle(appName: "farbatmung", event: "close")
    }
  }
}

#Preview {
  ColorBreathingView()
}
