import Foundation
import Testing

@testable import focuswatch_watch

@Suite("IncomingFileHandler")
struct IncomingFileHandlerTests {
        private func makeURL() -> URL {
            URL(fileURLWithPath: "/tmp/test-file.jpg")
        }

        @Test("nil metadata is ignored")
        @MainActor
        func missingMetadataIsIgnored() {
            let gallery = MockGalleryManager()
            let handler = IncomingFileHandler(galleryManager: gallery)
            handler.handle(fileURL: makeURL(), metadata: nil)
            #expect(gallery.receivedFileCalls.isEmpty)
        }

        @Test("metadata without syncType key is ignored")
        @MainActor
        func missingSyncTypeKeyInMetadataIsIgnored() {
            let gallery = MockGalleryManager()
            let handler = IncomingFileHandler(galleryManager: gallery)
            handler.handle(fileURL: makeURL(), metadata: ["other": "value"])
            #expect(gallery.receivedFileCalls.isEmpty)
        }

        @Test("checklist syncType routes to galleryManager")
        @MainActor
        func checklistSyncTypeRoutesToGalleryManager() {
            let gallery = MockGalleryManager()
            let handler = IncomingFileHandler(galleryManager: gallery)
            let url = makeURL()
            let metadata: [String: Any] = [SyncConstants.Keys.syncType: SyncMessageType.checklist.rawValue]
            handler.handle(fileURL: url, metadata: metadata)
            #expect(gallery.receivedFileCalls.count == 1)
            #expect(gallery.receivedFileCalls.first?.0 == url)
        }

        @Test("unknown syncType is ignored")
        @MainActor
        func unknownSyncTypeIsIgnored() {
            let gallery = MockGalleryManager()
            let handler = IncomingFileHandler(galleryManager: gallery)
            handler.handle(
                fileURL: makeURL(),
                metadata: [SyncConstants.Keys.syncType: "unknown_type"]
            )
            #expect(gallery.receivedFileCalls.isEmpty)
        }
}
