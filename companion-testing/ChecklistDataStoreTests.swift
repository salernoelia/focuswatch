import Combine
import Foundation
import Testing

@testable import focuswatch_companion

@Suite("ChecklistDataStore")
struct ChecklistDataStoreTests {
        private func makeDefaults() -> UserDefaults {
            UserDefaults(suiteName: UUID().uuidString)!
        }

        @Test("Init with empty defaults loads default ChecklistData")
        func initWithEmptyDefaultsLoadsDefaultChecklistData() {
            let store = ChecklistDataStore(userDefaults: makeDefaults(), debounceInterval: 0.0)
            #expect(store.checklistData.checklists.count == ChecklistData.default.checklists.count)
        }

        @Test("updateChecklistData publishes new value")
        func updateChecklistDataPublishesNewValue() {
            let store = ChecklistDataStore(userDefaults: makeDefaults(), debounceInterval: 0.0)
            let newData = ChecklistData(checklists: [Checklist(name: "Updated")])
            store.updateChecklistData(newData)
            #expect(store.checklistData.checklists.first?.name == "Updated")
        }

        @Test("Corrupted defaults loads default")
        func corruptedDefaultsLoadsDefault() {
            let defaults = makeDefaults()
            defaults.set(Data([0xFF, 0xFE, 0x00]), forKey: AppConstants.StorageKeys.checklistData)
            let store = ChecklistDataStore(userDefaults: defaults, debounceInterval: 0.0)
            #expect(store.checklistData.checklists.count == ChecklistData.default.checklists.count)
        }

        @Test("updateChecklistData persists after reinit")
        @MainActor
        func updateChecklistDataPersistsAfterReinit() async throws {
            let defaults = makeDefaults()
            let store = ChecklistDataStore(userDefaults: defaults, debounceInterval: 0.0)
            let newData = ChecklistData(checklists: [Checklist(name: "Persisted")])
            store.updateChecklistData(newData)

            try await Task.sleep(nanoseconds: 50_000_000)

            let store2 = ChecklistDataStore(userDefaults: defaults, debounceInterval: 0.0)
            #expect(store2.checklistData.checklists.first?.name == "Persisted")
        }
}
