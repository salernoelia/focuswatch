import SwiftData
import SwiftUI

@main
struct CompanionApp: App {
    @StateObject private var syncCoordinator: SyncCoordinator
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    init() {
        _syncCoordinator = StateObject(
            wrappedValue: SyncCoordinator.shared
        )
    }

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                CompanionView()
                    .environmentObject(syncCoordinator)
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
        .modelContainer(for: Event.self)
    }
}
