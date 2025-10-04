import SwiftUI



@main
struct WatchApp: App {
    @StateObject private var watchConnector = WatchConnector()
    @State private var testUsers: [TestUser] = []

    var body: some Scene {
        WindowGroup {
         
                WatchView()
                    .environmentObject(watchConnector)
            
            
        }
    }   
}
