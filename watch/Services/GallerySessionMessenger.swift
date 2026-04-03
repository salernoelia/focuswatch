import Foundation
import WatchConnectivity

/// Sends WCSession messages related to gallery image sync acknowledgment.
/// Has no knowledge of file storage — it only dispatches messages to the companion app.
class GallerySessionMessenger {

    private var pendingAcknowledgments: [String] = []
    private var acknowledgmentTimer: Timer?
    private let acknowledgmentBatchDelay: TimeInterval = 2.0

    func scheduleAcknowledgment(for imageNames: [String]) {
        pendingAcknowledgments.append(contentsOf: imageNames)

        acknowledgmentTimer?.invalidate()
        acknowledgmentTimer = Timer.scheduledTimer(
            withTimeInterval: acknowledgmentBatchDelay,
            repeats: false
        ) { [weak self] _ in
            self?.sendAcknowledgments()
        }
    }

    private func sendAcknowledgments() {
        guard !pendingAcknowledgments.isEmpty else { return }

        let imagesToAcknowledge = pendingAcknowledgments
        pendingAcknowledgments.removeAll()

        let message: [String: Any] = [
            SyncConstants.Keys.action: SyncConstants.Actions.acknowledgeImages,
            SyncConstants.Keys.receivedImages: imagesToAcknowledge,
            SyncConstants.Keys.timestamp: Date().timeIntervalSince1970
        ]

        #if DEBUG
            print("Watch GallerySessionMessenger: Sending acknowledgment for \(imagesToAcknowledge.count) images")
        #endif

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil) { [weak self] error in
                #if DEBUG
                    print("Watch GallerySessionMessenger: Acknowledgment failed: \(error.localizedDescription)")
                #endif
                self?.pendingAcknowledgments.append(contentsOf: imagesToAcknowledge)
            }
        } else {
            WCSession.default.transferUserInfo(message)
        }
    }

    func requestMissingImages(_ imageNames: [String]) {
        guard !imageNames.isEmpty else { return }

        let message: [String: Any] = [
            SyncConstants.Keys.action: SyncConstants.Actions.requestMissingImages,
            SyncConstants.Keys.missingImages: imageNames,
            SyncConstants.Keys.timestamp: Date().timeIntervalSince1970
        ]

        #if DEBUG
            print("Watch GallerySessionMessenger: Requesting \(imageNames.count) missing images: \(imageNames)")
        #endif

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: nil)
        } else {
            WCSession.default.transferUserInfo(message)
        }
    }

    func reportSyncStatus(existing: Set<String>, missing: Set<String>) {
        let status: String
        if missing.isEmpty {
            status = SyncConstants.Status.complete
        } else if existing.isEmpty {
            status = SyncConstants.Status.failed
        } else {
            status = SyncConstants.Status.partial
        }

        let message: [String: Any] = [
            SyncConstants.Keys.action: SyncConstants.Actions.reportSyncStatus,
            SyncConstants.Keys.syncStatus: status,
            SyncConstants.Keys.receivedImages: Array(existing),
            SyncConstants.Keys.missingImages: Array(missing),
            SyncConstants.Keys.timestamp: Date().timeIntervalSince1970
        ]

        #if DEBUG
            print("Watch GallerySessionMessenger: Reporting sync status: \(status) (received: \(existing.count), missing: \(missing.count))")
        #endif

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: nil)
        }
    }
}
