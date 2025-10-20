import Foundation
import SwiftData
import WatchConnectivity

extension WatchConnector {

  func syncCalendarToWatch() {
    guard WCSession.default.isReachable else {
      lastError = .watchNotReachable
      return
    }

    Task { @MainActor in
      let descriptor = FetchDescriptor<Event>()
      let context = ModelContext(ModelContainerProvider.shared.container)

      guard let events = try? context.fetch(descriptor) else {
        return
      }

      let transfers = events.map { EventTransfer(from: $0) }

      do {
        let data = try JSONEncoder().encode(transfers)
        let message: [String: Any] = [
          "action": "updateCalendar",
          "data": data.base64EncodedString(),
        ]

        WCSession.default.sendMessage(message, replyHandler: nil) { error in
          let appError = AppError.watchMessageFailed(underlying: error)
          #if DEBUG
            ErrorLogger.log(appError)
          #endif
          DispatchQueue.main.async {
            self.lastError = appError
          }
        }
      } catch {
        let appError = AppError.encodingFailed(type: "calendar events", underlying: error)
        #if DEBUG
          ErrorLogger.log(appError)
        #endif
        DispatchQueue.main.async {
          self.lastError = appError
        }
      }
    }
  }
}
