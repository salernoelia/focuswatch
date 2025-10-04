import SwiftUI

@main
struct CompanionApp: App {
    @StateObject private var watchConnector = WatchConnector()
    
    var body: some Scene {
        WindowGroup {
           CompanionView()
        }
    }
}


