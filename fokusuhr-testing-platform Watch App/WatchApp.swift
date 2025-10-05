import SwiftUI

@main
struct WatchApp: App {
  @StateObject private var watchConnector = WatchConnector()

  var body: some Scene {
    WindowGroup {

      WatchView()
        .environmentObject(watchConnector)
    }
  }
}
