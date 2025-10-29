import SwiftUI

struct FidgetToyView: View {
  @StateObject private var viewModel = FidgetToyViewModel()
  private let telemetryManager = TelemetryManager.shared
  private let appLogger = AppLogger.shared
  private let appName = "fidget_toy"

  var body: some View {
    ZStack {
      Color.black
        .ignoresSafeArea()
      Circle()
        .fill(Color.gray)
        .frame(width: 56, height: 56)
        .offset(viewModel.position)
        .gesture(
          DragGesture()
            .onChanged { value in
              viewModel.updatePosition(value)
            }
            .onEnded { _ in
              viewModel.endDrag()
            }
        )
        .animation(.spring(), value: viewModel.position)
    }
    .onAppear {
      if let data = telemetryManager.prepareTelemetryData(eventType: "app_opened") {
        Task {
          await appLogger.logEvent(appName: appName, watchId: TelemetryManager.watchId(), data: data)
        }
      }
    }
    .onDisappear {
      if let data = telemetryManager.prepareTelemetryData(eventType: "app_closed") {
        Task {
          await appLogger.logEvent(appName: appName, watchId: TelemetryManager.watchId(), data: data)
        }
      }
    }
  }
}

#Preview {
  FidgetToyView()
}
