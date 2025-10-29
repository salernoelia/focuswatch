import SwiftUI
import UserNotifications
import WatchKit

struct PomodoroView: View {
  @ObservedObject var viewModel = PomodoroViewModel.shared
  private let appLogger = AppLogger.shared

  var body: some View {
    TabView {
      PomodoroTimerView(viewModel: viewModel)
      PomodoroConfigView(viewModel: viewModel)
    }
    .tabViewStyle(.page)
    .onAppear {
      viewModel.restoreState()
      appLogger.logViewLifecycle(appName: "pomodoro", event: "open")
    }
    .onDisappear {
      appLogger.logViewLifecycle(appName: "pomodoro", event: "closed")
    }
  }
}

#Preview {
  PomodoroView()
}
