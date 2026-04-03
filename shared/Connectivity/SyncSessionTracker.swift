import Foundation

struct SyncState: Codable {
    let id: String
    var requiredImages: Set<String>
    var transferredImages: Set<String>
    var acknowledgedImages: Set<String>
    var failedImages: Set<String>
    var retryCount: Int
    var checklistSynced: Bool
    var createdAt: Date
    var lastUpdated: Date

    var isComplete: Bool {
        checklistSynced && missingImages.isEmpty
    }

    var missingImages: Set<String> {
        requiredImages.subtracting(acknowledgedImages)
    }

    var allImagesAcknowledged: Bool {
        requiredImages.isSubset(of: acknowledgedImages)
    }

    var needsRetry: Bool {
        !isComplete && retryCount < SyncConstants.Timing.maxRetries && !missingImages.isEmpty
    }

    init(id: String = UUID().uuidString, requiredImages: Set<String> = []) {
        self.id = id
        self.requiredImages = requiredImages
        self.transferredImages = []
        self.acknowledgedImages = []
        self.failedImages = []
        self.retryCount = 0
        self.checklistSynced = false
        self.createdAt = Date()
        self.lastUpdated = Date()
    }

    mutating func markImageTransferred(_ imageName: String) {
        transferredImages.insert(imageName)
        failedImages.remove(imageName)
        lastUpdated = Date()
    }

    mutating func markImageFailed(_ imageName: String) {
        failedImages.insert(imageName)
        lastUpdated = Date()
    }

    mutating func markImagesAcknowledged(_ imageNames: [String]) {
        for name in imageNames {
            acknowledgedImages.insert(name)
            failedImages.remove(name)
        }
        lastUpdated = Date()
    }

    mutating func markChecklistSynced() {
        checklistSynced = true
        lastUpdated = Date()
    }

    mutating func incrementRetry() {
        retryCount += 1
        lastUpdated = Date()
    }
}

protocol SyncSessionTracking: AnyObject {
    var currentState: SyncState? { get }
    func startNewSync(id: String, requiredImages: Set<String>)
    func updateState(_ update: (inout SyncState) -> Void)
    func completeCurrentSync()
    func cancelCurrentSync()
    func clear()
}

final class SyncSessionTracker: SyncSessionTracking {
    private(set) var currentState: SyncState?

    func startNewSync(id: String, requiredImages: Set<String>) {
        currentState = SyncState(id: id, requiredImages: requiredImages)
    }

    func updateState(_ update: (inout SyncState) -> Void) {
        guard var state = currentState else { return }
        update(&state)
        currentState = state
    }

    func completeCurrentSync() {
        currentState = nil
    }

    func cancelCurrentSync() {
        currentState = nil
    }

    func clear() {
        currentState = nil
    }
}
