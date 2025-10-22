import SwiftData
import SwiftUI

@main
struct CompanionApp: App {
  @StateObject private var watchConnector = WatchConnector.shared
  @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

  var body: some Scene {
    WindowGroup {
      if hasCompletedOnboarding {
        CompanionView()
          .environmentObject(watchConnector)
      } else {
        OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
      }
    }
    .modelContainer(for: Event.self)
  }
}
