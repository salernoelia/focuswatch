import Foundation
import SwiftData
import WatchConnectivity

final class CalendarSyncService {
    static let shared = CalendarSyncService()

    private let transport: ConnectivityTransport
    private var lastSyncedHash: Int?

    init(transport: ConnectivityTransport = .shared) {
        self.transport = transport
    }

    func sync() {
        Task {
            let descriptor = FetchDescriptor<Event>()
            let context = ModelContext(ModelContainerProvider.shared.container)

            guard let events = try? context.fetch(descriptor) else {
                #if DEBUG
                    print("❌ Failed to fetch events from iOS")
                #endif
                return
            }

            let transfers = events.map { EventTransfer(from: $0) }
            await syncEvents(transfers)
        }
    }

    func syncEvents(_ events: [EventTransfer]) async {
        let newHash = computeHash(events)

        if let lastHash = lastSyncedHash, lastHash == newHash {
            #if DEBUG
                print("⏭️ iOS: Calendar unchanged (hash: \(newHash)), skipping sync")
            #endif
            return
        }

        do {
            let data = try JSONEncoder().encode(events)
            let context: [String: Any] = [
                SyncConstants.Keys.calendarData: data,
                SyncConstants.Keys.timestamp: Date().timeIntervalSince1970
            ]

            try transport.updateApplicationContext(context)
            lastSyncedHash = newHash

            #if DEBUG
                print("iOS: Calendar synced - \(events.count) events sent")
            #endif
        } catch {
            #if DEBUG
                ErrorLogger.log(AppError.encodingFailed(type: "calendar events", underlying: error))
            #endif
        }
    }

    private func computeHash(_ events: [EventTransfer]) -> Int {
        var hasher = Hasher()
        hasher.combine(events.count)
        for event in events {
            hasher.combine(event.id)
            hasher.combine(event.title)
            hasher.combine(event.eventDescription)
            hasher.combine(event.startTime)
            hasher.combine(event.repeatRule.rawValue)
            hasher.combine(event.reminders.count)
            for reminder in event.reminders {
                hasher.combine(reminder.id)
                hasher.combine(reminder.minutesBefore)
                hasher.combine(reminder.shouldLaunchApp)
                hasher.combine(reminder.message)
            }
        }
        return hasher.finalize()
    }
}

