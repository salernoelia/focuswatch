import Foundation
import SwiftData
import WatchConnectivity

extension WatchConnector {

  func syncCalendarToWatch() {
    Task { @MainActor in
      let descriptor = FetchDescriptor<Event>()
      let context = ModelContext(ModelContainerProvider.shared.container)

      guard let events = try? context.fetch(descriptor) else {
        #if DEBUG
          print("❌ Failed to fetch events from iOS")
        #endif
        return
      }

      let transfers = events.map { EventTransfer(from: $0) }

      #if DEBUG
        print("📅 iOS: Preparing to sync \(transfers.count) calendar events to watch")
        for event in transfers {
          print("  • \(event.title) - \(event.startTime) - Reminders: \(event.reminders.count)")
        }
      #endif

      do {
        let data = try JSONEncoder().encode(transfers)
        let applicationContext: [String: Any] = [
          "calendarData": data.base64EncodedString(),
          "timestamp": Date().timeIntervalSince1970,
        ]

        try WCSession.default.updateApplicationContext(applicationContext)

        #if DEBUG
          print("✅ iOS: Calendar synced to watch via background context")
          print("   → \(transfers.count) events sent")
          print("   → Watch will receive even if app not running")
        #endif

      } catch {
        let appError = AppError.encodingFailed(type: "calendar events", underlying: error)
        #if DEBUG
          ErrorLogger.log(appError)
          print("❌ iOS: Failed to update application context: \(error)")
        #endif
        DispatchQueue.main.async {
          self.lastError = appError
        }
      }
    }
  }
}
