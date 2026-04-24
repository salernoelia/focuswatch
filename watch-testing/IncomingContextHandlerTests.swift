import Foundation
import Testing

@testable import focuswatch_watch

@Suite("IncomingContextHandler")
struct IncomingContextHandlerTests {
        private func makeChecklistBytes() throws -> Data {
            try JSONEncoder().encode(ChecklistData(checklists: [Checklist(name: "Test")]))
        }

        @Test("checklistData key triggers checklistManager update")
        @MainActor
        func checklistDataKeyTriggersChecklistManagerUpdate() throws {
            let checklist = MockChecklistViewModel()
            let gallery = MockGalleryManager()
            let handler = IncomingContextHandler(checklistManager: checklist, galleryManager: gallery)

            let bytes = try makeChecklistBytes()
            let context: [String: Any] = [SyncConstants.Keys.checklistData: bytes]

            handler.handle(
                context,
                updateCalendarEvents: { _ in },
                handleLevelUpdate: { _ in },
                handleConfigurationsUpdate: { _ in },
                handleLegacyAction: { _, _ in }
            )

            #expect(checklist.updateCalls.count == 1)
            #expect(checklist.updateCalls.first?.data == bytes)
            #expect(checklist.updateCalls.first?.forceOverwrite == false)
        }

        @Test("checklistData with images calls saveGalleryImages")
        @MainActor
        func checklistDataWithImagesCallsSaveGalleryImages() throws {
            let checklist = MockChecklistViewModel()
            let gallery = MockGalleryManager()
            let handler = IncomingContextHandler(checklistManager: checklist, galleryManager: gallery)

            let bytes = try makeChecklistBytes()
            let imageData: [String: Data] = ["img-a": Data([1, 2, 3])]
            let context: [String: Any] = [
                SyncConstants.Keys.checklistData: bytes,
                SyncConstants.Keys.checklistImageData: imageData,
            ]

            handler.handle(
                context,
                updateCalendarEvents: { _ in },
                handleLevelUpdate: { _ in },
                handleConfigurationsUpdate: { _ in },
                handleLegacyAction: { _, _ in }
            )

            #expect(gallery.savedImageDataCalls.count == 1)
            #expect(gallery.savedImageDataCalls.first?["img-a"] == Data([1, 2, 3]))
        }

        @Test("checklistData without images does not call saveGalleryImages")
        @MainActor
        func checklistDataWithoutImagesDoesNotCallSaveGalleryImages() throws {
            let checklist = MockChecklistViewModel()
            let gallery = MockGalleryManager()
            let handler = IncomingContextHandler(checklistManager: checklist, galleryManager: gallery)

            let bytes = try makeChecklistBytes()
            let context: [String: Any] = [SyncConstants.Keys.checklistData: bytes]

            handler.handle(
                context,
                updateCalendarEvents: { _ in },
                handleLevelUpdate: { _ in },
                handleConfigurationsUpdate: { _ in },
                handleLegacyAction: { _, _ in }
            )

            #expect(gallery.savedImageDataCalls.isEmpty)
        }

        @Test("levelData key triggers handleLevelUpdate callback")
        @MainActor
        func levelDataKeyTriggersLevelUpdateCallback() {
            let checklist = MockChecklistViewModel()
            let gallery = MockGalleryManager()
            let handler = IncomingContextHandler(checklistManager: checklist, galleryManager: gallery)

            let levelBytes = Data([1, 2, 3])
            let context: [String: Any] = [SyncConstants.Keys.levelData: levelBytes]

            var receivedData: Data?
            handler.handle(
                context,
                updateCalendarEvents: { _ in },
                handleLevelUpdate: { receivedData = $0 },
                handleConfigurationsUpdate: { _ in },
                handleLegacyAction: { _, _ in }
            )

            #expect(receivedData == levelBytes)
        }

        @Test("configData key triggers handleConfigurationsUpdate callback")
        @MainActor
        func configDataKeyTriggersConfigurationsCallback() {
            let checklist = MockChecklistViewModel()
            let gallery = MockGalleryManager()
            let handler = IncomingContextHandler(checklistManager: checklist, galleryManager: gallery)

            let configBytes = Data([9, 8, 7])
            let context: [String: Any] = [SyncConstants.Keys.appConfigurations: configBytes]

            var receivedData: Data?
            handler.handle(
                context,
                updateCalendarEvents: { _ in },
                handleLevelUpdate: { _ in },
                handleConfigurationsUpdate: { receivedData = $0 },
                handleLegacyAction: { _, _ in }
            )

            #expect(receivedData == configBytes)
        }

        @Test("handle returns true when checklistData is present")
        @MainActor
        func handleReturnsTrueWhenChecklistDataPresent() throws {
            let handler = IncomingContextHandler(
                checklistManager: MockChecklistViewModel(),
                galleryManager: MockGalleryManager()
            )
            let bytes = try makeChecklistBytes()
            let result = handler.handle(
                [SyncConstants.Keys.checklistData: bytes],
                updateCalendarEvents: { _ in },
                handleLevelUpdate: { _ in },
                handleConfigurationsUpdate: { _ in },
                handleLegacyAction: { _, _ in }
            )
            #expect(result)
        }

        @Test("handle returns false when no checklistData is present")
        @MainActor
        func handleReturnsFalseWhenNoChecklistDataPresent() {
            let handler = IncomingContextHandler(
                checklistManager: MockChecklistViewModel(),
                galleryManager: MockGalleryManager()
            )
            let result = handler.handle(
                [SyncConstants.Keys.levelData: Data([1])],
                updateCalendarEvents: { _ in },
                handleLevelUpdate: { _ in },
                handleConfigurationsUpdate: { _ in },
                handleLegacyAction: { _, _ in }
            )
            #expect(!result)
        }

        @Test("missing images key in context does not crash")
        @MainActor
        func missingImagesKeyDoesNotCrash() throws {
            let handler = IncomingContextHandler(
                checklistManager: MockChecklistViewModel(),
                galleryManager: MockGalleryManager()
            )
            let bytes = try makeChecklistBytes()
            handler.handle(
                [SyncConstants.Keys.checklistData: bytes],
                updateCalendarEvents: { _ in },
                handleLevelUpdate: { _ in },
                handleConfigurationsUpdate: { _ in },
                handleLegacyAction: { _, _ in }
            )
        }
}
