import SwiftUI
import WatchKit

@main
struct WatchApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Hello")
        }
        .backgroundTask(.appRefresh("my-identifier")) { task in
            print("Refresh")
        }
    }
}
