import SwiftUI

@main
struct WatchApp: App {
    @StateObject private var watchConnector = WatchConnector()
    @StateObject private var exerciseManager = ExerciseManager()

    var body: some Scene {
        WindowGroup {

            WatchView()
                .environmentObject(watchConnector)
                .environmentObject(exerciseManager)
        }
    }
}
