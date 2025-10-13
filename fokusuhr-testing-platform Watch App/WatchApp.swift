import ClockKit
import SwiftUI

@main
struct WatchApp: App {
  @StateObject private var watchConnector = WatchConnector()
  @StateObject private var exerciseManager = ExerciseManager()

  init() {
    CLKComplicationServer.sharedInstance().activeComplications?.forEach { complication in
      CLKComplicationServer.sharedInstance().reloadTimeline(for: complication)
    }
  }

  var body: some Scene {
    WindowGroup {

      WatchView()
        .environmentObject(watchConnector)
        .environmentObject(exerciseManager)
    }
  }
}
