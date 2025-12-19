import SwiftUI
import WatchKit

struct ColorBreathingView: View {
  @StateObject private var viewModel = ColorBreathingViewModel()
  @Environment(\.scenePhase) private var scenePhase
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
        }
        .frame(width: 120, height: 120)

        VStack(spacing: 4) {
          Text(viewModel.isInhaling ? "Einatmen" : "Ausatmen")
            .font(.caption)
            .foregroundColor(.white.opacity(0.8))

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
    .onChange(of: scenePhase) { oldPhase, newPhase in
      if newPhase == .active && oldPhase != .active {
        viewModel.startBreathing()
      } else if newPhase != .active {
        viewModel.stopBreathing()
      }
    }
  }
}

#Preview {
  ColorBreathingView()
}
