import Foundation
import Testing

@testable import focuswatch_companion

@Suite("SyncStateManager")
struct SyncStateManagerTests {
        @Test("startNewSync creates current state")
        func startNewSyncCreatesCurrentState() {
            let store = MockSyncSessionStateStore()
            let manager = SyncStateManager(store: store)
            manager.startNewSync(id: "sync-1", requiredImages: ["img-a"])
            #expect(manager.currentState != nil)
            #expect(manager.currentState?.id == "sync-1")
            #expect(manager.currentState?.requiredImages == ["img-a"])
        }

        @Test("startNewSync while incomplete archives to history")
        func startNewSyncWhileIncompleteArchivesToHistory() {
            let store = MockSyncSessionStateStore()
            let manager = SyncStateManager(store: store)
            manager.startNewSync(id: "sync-1", requiredImages: ["img-a"])
            manager.startNewSync(id: "sync-2", requiredImages: [])
            #expect(manager.syncHistory.count == 1)
            #expect(manager.syncHistory.first?.id == "sync-1")
            #expect(manager.currentState?.id == "sync-2")
        }

        @Test("updateState propagates change")
        func updateStatePropagatesChange() {
            let store = MockSyncSessionStateStore()
            let manager = SyncStateManager(store: store)
            manager.startNewSync(id: "sync-1", requiredImages: [])
            manager.updateState { state in
                state.markChecklistSynced()
            }
            #expect(manager.currentState?.checklistSynced == true)
        }

        @Test("completeCurrentSync moves to history")
        func completeCurrentSyncMovesToHistory() {
            let store = MockSyncSessionStateStore()
            let manager = SyncStateManager(store: store)
            manager.startNewSync(id: "sync-1", requiredImages: [])
            manager.completeCurrentSync()
            #expect(manager.currentState == nil)
            #expect(manager.syncHistory.count == 1)
            #expect(manager.syncHistory.first?.id == "sync-1")
        }

        @Test("cancelCurrentSync increments retry in history")
        func cancelCurrentSyncIncrementsRetryInHistory() {
            let store = MockSyncSessionStateStore()
            let manager = SyncStateManager(store: store)
            manager.startNewSync(id: "sync-1", requiredImages: [])
            manager.cancelCurrentSync()
            #expect(manager.currentState == nil)
            #expect(manager.syncHistory.first?.retryCount == 1)
        }

        @Test("clearAll resets everything")
        func clearAllResetsEverything() {
            let store = MockSyncSessionStateStore()
            let manager = SyncStateManager(store: store)
            manager.startNewSync(id: "sync-1", requiredImages: [])
            manager.completeCurrentSync()
            manager.startNewSync(id: "sync-2", requiredImages: [])
            manager.clearAll()
            #expect(manager.currentState == nil)
            #expect(manager.syncHistory.isEmpty)
        }

        @Test("loadState restores from store")
        func loadStateRestoresFromStore() {
            let store = MockSyncSessionStateStore()
            let savedState = SyncState(id: "saved-sync", requiredImages: ["img-x"])
            store.storedState = savedState

            let manager = SyncStateManager(store: store)
            #expect(manager.currentState?.id == "saved-sync")
            #expect(manager.currentState?.requiredImages == ["img-x"])
        }
}
