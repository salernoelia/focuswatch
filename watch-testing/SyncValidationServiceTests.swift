import Foundation
import Testing

@testable import focuswatch_watch

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

        @Test("All images exist returns complete")
        @MainActor
        func allImagesExistReturnsComplete() {
            let service = SyncValidationService()
            let data = ChecklistData(
                checklists: [
                    Checklist(
                        name: "List",
                        items: [
                            ChecklistItem(title: "A", imageName: "img-a"),
                            ChecklistItem(title: "B", imageName: "img-b"),
                        ]
                    )
                ]
            )
            let result = service.validate(
                checklistData: data,
                transportReachable: true,
                imageExists: { _ in true },
                requestMissingImages: { _ in }
            )
            #expect(result.status == SyncConstants.Status.complete)
            #expect(result.progress == 1.0)
            #expect(result.missingImages.isEmpty)
        }

        @Test("No images exist returns pending")
        @MainActor
        func noImagesExistReturnsPending() {
            let service = SyncValidationService()
            let data = ChecklistData(
                checklists: [
                    Checklist(
                        name: "List",
                        items: [
                            ChecklistItem(title: "A", imageName: "img-a"),
                            ChecklistItem(title: "B", imageName: "img-b"),
                        ]
                    )
                ]
            )
            let result = service.validate(
                checklistData: data,
                transportReachable: false,
                imageExists: { _ in false },
                requestMissingImages: { _ in }
            )
            #expect(result.status == SyncConstants.Status.pending)
            #expect(result.progress == 0.0)
        }

        @Test("Some images exist returns partial with correct progress")
        @MainActor
        func someImagesExistReturnsPartial() {
            let service = SyncValidationService()
            let data = ChecklistData(
                checklists: [
                    Checklist(
                        name: "List",
                        items: [
                            ChecklistItem(title: "A", imageName: "img-a"),
                            ChecklistItem(title: "B", imageName: "img-b"),
                            ChecklistItem(title: "C", imageName: "img-c"),
                            ChecklistItem(title: "D", imageName: "img-d"),
                        ]
                    )
                ]
            )
            let result = service.validate(
                checklistData: data,
                transportReachable: false,
                imageExists: { name in name == "img-a" || name == "img-b" },
                requestMissingImages: { _ in }
            )
            #expect(result.status == SyncConstants.Status.partial)
            #expect(abs(result.progress - 0.5) < 0.0001)
        }

        @Test("Transport not reachable skips request")
        @MainActor
        func transportNotReachableSkipsRequest() {
            let service = SyncValidationService()
            let data = ChecklistData(
                checklists: [Checklist(name: "L", items: [ChecklistItem(title: "A", imageName: "img-a")])]
            )
            var requestCount = 0
            _ = service.validate(
                checklistData: data,
                transportReachable: false,
                imageExists: { _ in false },
                requestMissingImages: { _ in requestCount += 1 }
            )
            #expect(requestCount == 0)
        }

        @Test("Reset clears pending and allows new request")
        @MainActor
        func resetClearsPendingAndAllowsNewRequest() {
            let service = SyncValidationService()
            let data = ChecklistData(
                checklists: [Checklist(name: "L", items: [ChecklistItem(title: "A", imageName: "img-a")])]
            )
            var requestCount = 0
            _ = service.validate(
                checklistData: data,
                transportReachable: true,
                imageExists: { _ in false },
                requestMissingImages: { _ in requestCount += 1 }
            )
            service.reset()
            _ = service.validate(
                checklistData: data,
                transportReachable: true,
                imageExists: { _ in false },
                requestMissingImages: { _ in requestCount += 1 }
            )
            #expect(requestCount == 2)
        }

        @Test("Empty imageName items are excluded from required set")
        @MainActor
        func emptyItemImageNamesAreExcludedFromRequired() {
            let service = SyncValidationService()
            let data = ChecklistData(
                checklists: [
                    Checklist(
                        name: "List",
                        items: [
                            ChecklistItem(title: "No image", imageName: ""),
                            ChecklistItem(title: "Also no image"),
                        ]
                    )
                ]
            )
            let result = service.validate(
                checklistData: data,
                transportReachable: true,
                imageExists: { _ in false },
                requestMissingImages: { _ in }
            )
            #expect(result.status == SyncConstants.Status.complete)
            #expect(result.missingImages.isEmpty)
        }
}
