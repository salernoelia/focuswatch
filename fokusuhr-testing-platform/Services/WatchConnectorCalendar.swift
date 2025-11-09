import Foundation
import SwiftData
import WatchConnectivity

extension WatchConnector {

  func syncCalendarToWatch() {
    Task { [weak self] in
      let descriptor = FetchDescriptor<Event>()
      let context = ModelContext(ModelContainerProvider.shared.container)

      guard let events = try? context.fetch(descriptor) else {
        #if DEBUG
          print("❌ Failed to fetch events from iOS")
        #endif
        return
      }

      guard let self = self else { return }

      let transfers = events.map { EventTransfer(from: $0) }
      let newHash = computeCalendarHash(transfers)

      if let lastHash = lastCalendarSyncHash, lastHash == newHash {
        #if DEBUG
          print("⏭️ iOS: Calendar unchanged (hash: \(newHash)), skipping sync to watch")
        #endif
        return
      }

      #if DEBUG
        print("📅 iOS: Preparing to sync \(transfers.count) calendar events to watch")
        print("   → New hash: \(newHash), Last hash: \(lastCalendarSyncHash ?? -1)")
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

        lastCalendarSyncHash = newHash

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
        await MainActor.run {
          self.lastError = appError
        }
      }
    }
  }

  private func computeCalendarHash(_ events: [EventTransfer]) -> Int {
    var hasher = Hasher()
    hasher.combine(events.count)
    for event in events {
      hasher.combine(event.id)
      hasher.combine(event.title)
      hasher.combine(event.eventDescription)
      hasher.combine(event.startTime)
      hasher.combine(event.reminders.count)
    }
    return hasher.finalize()
  }
}
