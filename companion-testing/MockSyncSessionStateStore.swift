import Foundation

@testable import focuswatch_companion

final class MockSyncSessionStateStore: SyncSessionStateStore {
    var storedState: SyncState?
    var storedHistory: [SyncState] = []

    func loadCurrentState() -> SyncState? {
        storedState
    }

    func loadHistory() -> [SyncState] {
        storedHistory
    }

    func saveCurrentState(_ state: SyncState?) {
        storedState = state
    }

    func saveHistory(_ history: [SyncState]) {
        storedHistory = history
    }

    func clear() {
        storedState = nil
        storedHistory = []
    }
}
