import Foundation

@testable import focuswatch_watch

final class MockGalleryManager: GalleryManager {
    private(set) var savedImageDataCalls: [[String: Data]] = []
    private(set) var receivedFileCalls: [(URL, [String: Any]?)] = []

    override func saveGalleryImages(_ imageData: [String: Data]) {
        savedImageDataCalls.append(imageData)
    }

    override func handleReceivedFile(fileURL: URL, metadata: [String: Any]?) {
        receivedFileCalls.append((fileURL, metadata))
    }
}
