import SwiftUI
import UserNotifications
import WatchKit

struct PomodoroView: View {
  @ObservedObject var viewModel = PomodoroViewModel.shared
  private let telemetryManager = TelemetryManager.shared
  private let appLogger = AppLogger.shared
  private let appName = "pomodoro"

  var body: some View {
    TabView {
      PomodoroTimerView(viewModel: viewModel)
      PomodoroConfigView(viewModel: viewModel)
    }
    .tabViewStyle(.page)
    .onAppear {
      viewModel.restoreState()
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
  PomodoroView()
}
