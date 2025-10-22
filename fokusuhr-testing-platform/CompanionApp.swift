import SwiftData
import SwiftUI

@main
struct CompanionApp: App {
  @StateObject private var watchConnector = WatchConnector.shared

  var body: some Scene {
    WindowGroup {
      CompanionView()
        .environmentObject(watchConnector)
    }
    .modelContainer(for: Event.self)
  }
}
