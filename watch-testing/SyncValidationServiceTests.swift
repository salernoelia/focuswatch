import Foundation
import Testing

#if canImport(watch)
@testable import watch
#endif

#if canImport(watch)
@Suite("Watch Sync Validation Regression")
struct SyncValidationServiceTests {
    @Test("No required images is immediately complete")
    @MainActor
    func noRequiredImagesIsImmediatelyComplete() {
        let service = SyncValidationService()
        let data = ChecklistData(checklists: [Checklist(name: "Checklist", items: [])])

        var requestCount = 0
        let result = service.validate(
            checklistData: data,
            transportReachable: true,
            imageExists: { _ in true },
            requestMissingImages: { _ in requestCount += 1 }
        )

        #expect(result.status == SyncConstants.Status.complete)
        #expect(result.progress == 1.0)
        #expect(result.missingImages.isEmpty)
        #expect(requestCount == 0)
    }

    @Test("Missing image request is throttled while pending")
    @MainActor
    func missingImageRequestIsThrottledWhilePending() {
        let service = SyncValidationService()
        let data = ChecklistData(
            checklists: [
                Checklist(
                    name: "Checklist",
                    items: [
                        ChecklistItem(title: "A", imageName: "img-a"),
                        ChecklistItem(title: "B", imageName: "img-b"),
                    ]
                )
            ]
        )

        var requestCount = 0
        var requestedImages: [[String]] = []

        let first = service.validate(
            checklistData: data,
            transportReachable: true,
            imageExists: { imageName in imageName == "img-a" },
            requestMissingImages: { missing in
                requestCount += 1
                requestedImages.append(missing.sorted())
            }
        )

        let second = service.validate(
            checklistData: data,
            transportReachable: true,
            imageExists: { imageName in imageName == "img-a" },
            requestMissingImages: { missing in
                requestCount += 1
                requestedImages.append(missing.sorted())
            }
        )

        #expect(first.status == SyncConstants.Status.partial)
        #expect(abs(first.progress - 0.5) < 0.0001)
        #expect(first.missingImages.sorted() == ["img-b"])

        #expect(second.status == SyncConstants.Status.partial)
        #expect(second.missingImages.sorted() == ["img-b"])

        #expect(requestCount == 1)
        #expect(requestedImages == [["img-b"]])
    }
}
#endif
