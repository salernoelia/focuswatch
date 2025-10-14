import ClockKit
import SwiftUI

@main
struct WatchApp: App {
  @StateObject private var watchConnector = WatchConnector()
  @StateObject private var writingExerciseManager = WritingExerciseManager()

  var body: some Scene {
    WindowGroup {

      WatchView()
        .environmentObject(watchConnector)
        .environmentObject(writingExerciseManager)
    }
  }
}
