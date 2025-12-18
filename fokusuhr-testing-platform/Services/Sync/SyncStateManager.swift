import Combine
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

final class SyncStateManager: ObservableObject {
    static let shared = SyncStateManager()

    @Published private(set) var currentState: SyncState?
    @Published private(set) var syncHistory: [SyncState] = []

    private let stateKey = "currentSyncState"
    private let historyKey = "syncStateHistory"
    private let maxHistoryCount = 10

    private init() {
        loadState()
    }

    func getCurrentState() -> SyncState? {
        currentState
    }

    func startNewSync(id: String, requiredImages: Set<String>) {
        if let existing = currentState, !existing.isComplete {
            archiveState(existing)
        }

        let newState = SyncState(id: id, requiredImages: requiredImages)
        currentState = newState
        saveState()

        #if DEBUG
            print("iOS SyncStateManager: Started new sync \(id) with \(requiredImages.count) required images")
        #endif
    }

    func updateState(_ update: (inout SyncState) -> Void) {
        guard var state = currentState else { return }
        update(&state)
        currentState = state
        saveState()
    }

    func completeCurrentSync() {
        guard let state = currentState else { return }
        archiveState(state)
        currentState = nil
        saveState()

        #if DEBUG
            print("iOS SyncStateManager: Completed sync \(state.id)")
        #endif
    }

    func cancelCurrentSync() {
        guard let state = currentState else { return }
        var cancelled = state
        cancelled.incrementRetry()
        archiveState(cancelled)
        currentState = nil
        saveState()
    }

    private func archiveState(_ state: SyncState) {
        syncHistory.insert(state, at: 0)
        if syncHistory.count > maxHistoryCount {
            syncHistory = Array(syncHistory.prefix(maxHistoryCount))
        }
        saveHistory()
    }

    private func loadState() {
        if let data = UserDefaults.standard.data(forKey: stateKey),
           let state = try? JSONDecoder().decode(SyncState.self, from: data) {
            currentState = state
        }

        if let data = UserDefaults.standard.data(forKey: historyKey),
           let history = try? JSONDecoder().decode([SyncState].self, from: data) {
            syncHistory = history
        }
    }

    private func saveState() {
        if let state = currentState,
           let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: stateKey)
        } else {
            UserDefaults.standard.removeObject(forKey: stateKey)
        }
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(syncHistory) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }

    func clearAll() {
        currentState = nil
        syncHistory = []
        UserDefaults.standard.removeObject(forKey: stateKey)
        UserDefaults.standard.removeObject(forKey: historyKey)
    }
}
