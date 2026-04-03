import Combine
import Foundation

protocol SyncSessionStateStore {
    func loadCurrentState() -> SyncState?
    func loadHistory() -> [SyncState]
    func saveCurrentState(_ state: SyncState?)
    func saveHistory(_ history: [SyncState])
    func clear()
}

final class UserDefaultsSyncSessionStateStore: SyncSessionStateStore {
    private let stateKey = "currentSyncState"
    private let historyKey = "syncStateHistory"

    func loadCurrentState() -> SyncState? {
        guard let data = UserDefaults.standard.data(forKey: stateKey) else { return nil }
        return try? JSONDecoder().decode(SyncState.self, from: data)
    }

    func loadHistory() -> [SyncState] {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else { return [] }
        return (try? JSONDecoder().decode([SyncState].self, from: data)) ?? []
    }

    func saveCurrentState(_ state: SyncState?) {
        if let state,
            let data = try? JSONEncoder().encode(state)
        {
            UserDefaults.standard.set(data, forKey: stateKey)
        } else {
            UserDefaults.standard.removeObject(forKey: stateKey)
        }
    }

    func saveHistory(_ history: [SyncState]) {
        guard let data = try? JSONEncoder().encode(history) else { return }
        UserDefaults.standard.set(data, forKey: historyKey)
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: stateKey)
        UserDefaults.standard.removeObject(forKey: historyKey)
    }
}

final class SyncStateManager: ObservableObject {
    static let shared = SyncStateManager(store: UserDefaultsSyncSessionStateStore())

    @Published private(set) var currentState: SyncState?
    @Published private(set) var syncHistory: [SyncState] = []

    private let tracker: SyncSessionTracking
    private let store: SyncSessionStateStore?
    private let maxHistoryCount = 10

    init(
        tracker: SyncSessionTracking = SyncSessionTracker(),
        store: SyncSessionStateStore? = nil
    ) {
        self.tracker = tracker
        self.store = store
        loadState()
    }

    func getCurrentState() -> SyncState? {
        currentState
    }

    func startNewSync(id: String, requiredImages: Set<String>) {
        if let existing = currentState, !existing.isComplete {
            archiveState(existing)
        }

        tracker.startNewSync(id: id, requiredImages: requiredImages)
        currentState = tracker.currentState
        saveState()

        #if DEBUG
            print(
                "iOS SyncStateManager: Started new sync \(id) with \(requiredImages.count) required images"
            )
        #endif
    }

    func updateState(_ update: (inout SyncState) -> Void) {
        tracker.updateState(update)
        currentState = tracker.currentState
        saveState()
    }

    func completeCurrentSync() {
        guard let state = currentState else { return }
        archiveState(state)
        tracker.completeCurrentSync()
        currentState = tracker.currentState
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
        tracker.cancelCurrentSync()
        currentState = tracker.currentState
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
        currentState = store?.loadCurrentState()
        syncHistory = store?.loadHistory() ?? []
        if let state = currentState {
            tracker.startNewSync(id: state.id, requiredImages: state.requiredImages)
            tracker.updateState { trackedState in
                trackedState = state
            }
            currentState = tracker.currentState
        }
    }

    private func saveState() {
        store?.saveCurrentState(currentState)
    }

    private func saveHistory() {
        store?.saveHistory(syncHistory)
    }

    func clearAll() {
        tracker.clear()
        currentState = tracker.currentState
        syncHistory = []
        store?.clear()
    }
}
