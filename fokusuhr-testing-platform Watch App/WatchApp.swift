import ClockKit
import SwiftUI

@main
struct WatchApp: App {
  @StateObject private var watchConnector = WatchConnector()
  @StateObject private var WritingExerciseManager = WritingExerciseManager()

  var body: some Scene {
    WindowGroup {

      WatchView()
        .environmentObject(watchConnector)
        .environmentObject(WritingExerciseManager)
    }
  }
}
