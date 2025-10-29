import SwiftUI
import UserNotifications
import WatchKit

struct PomodoroView: View {
  @ObservedObject var viewModel = PomodoroViewModel.shared

  var body: some View {
    TabView {
      PomodoroTimerView(viewModel: viewModel)
      PomodoroConfigView(viewModel: viewModel)
    }
    .tabViewStyle(.page)
    .onAppear {
      viewModel.restoreState()
    }
  }
}

#Preview {
  PomodoroView()
}
