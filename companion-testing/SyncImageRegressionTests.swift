import Foundation
import Testing

@testable import focuswatch_companion

@Suite("Image Sync Session Regression")
struct SyncImageRegressionTests {
        @Test("Acknowledgment progression reaches completion")
        func acknowledgmentProgressionReachesCompletion() {
            let tracker = SyncSessionTracker()
            tracker.startNewSync(id: "sync-1", requiredImages: ["img-a", "img-b"])

            tracker.updateState { state in
                state.markChecklistSynced()
                state.markImagesAcknowledged(["img-a"])
            }

            let partialState = tracker.currentState
            #expect(partialState != nil)
            #expect(partialState?.checklistSynced == true)
            #expect(partialState?.isComplete == false)
            #expect(partialState?.missingImages == ["img-b"])

            tracker.updateState { state in
                state.markImagesAcknowledged(["img-b"])
            }

            let completeState = tracker.currentState
            #expect(completeState?.allImagesAcknowledged == true)
            #expect(completeState?.isComplete == true)
        }

        @Test("Retry requirement flips off at max retries")
        func retryRequirementFlipsOffAtMaxRetries() {
            let tracker = SyncSessionTracker()
            tracker.startNewSync(id: "sync-2", requiredImages: ["img-a", "img-b"])

            tracker.updateState { state in
                state.markChecklistSynced()
                state.markImagesAcknowledged(["img-a"])
            }

            #expect(tracker.currentState?.needsRetry == true)

            for _ in 0..<SyncConstants.Timing.maxRetries {
                tracker.updateState { state in
                    state.incrementRetry()
                }
            }

            #expect(tracker.currentState?.needsRetry == false)
        }

        @Test("Completing sync clears active session")
        func completingSyncClearsActiveSession() {
            let tracker = SyncSessionTracker()
            tracker.startNewSync(id: "sync-3", requiredImages: ["img-a"])

            tracker.updateState { state in
                state.markChecklistSynced()
                state.markImagesAcknowledged(["img-a"])
            }

            #expect(tracker.currentState?.isComplete == true)

            tracker.completeCurrentSync()

            #expect(tracker.currentState == nil)
        }

        @Test("Cancel sync clears current state")
        func cancelSyncClearsCurrentState() {
            let tracker = SyncSessionTracker()
            tracker.startNewSync(id: "sync-4", requiredImages: ["img-a"])
            tracker.cancelCurrentSync()
            #expect(tracker.currentState == nil)
        }

        @Test("Clear resets to nil with required images")
        func clearResetsToNilWithRequiredImages() {
            let tracker = SyncSessionTracker()
            tracker.startNewSync(id: "sync-5", requiredImages: ["img-a", "img-b"])
            tracker.clear()
            #expect(tracker.currentState == nil)
        }

        @Test("markImageTransferred removes from failed images")
        func markImageTransferredRemovesFromFailed() {
            let tracker = SyncSessionTracker()
            tracker.startNewSync(id: "sync-6", requiredImages: ["img-a"])
            tracker.updateState { state in
                state.markImageFailed("img-a")
            }
            #expect(tracker.currentState?.failedImages.contains("img-a") == true)
            tracker.updateState { state in
                state.markImageTransferred("img-a")
            }
            #expect(tracker.currentState?.failedImages.contains("img-a") == false)
        }

        @Test("markImagesAcknowledged removes from failed images")
        func markImagesAcknowledgedRemovesFromFailed() {
            let tracker = SyncSessionTracker()
            tracker.startNewSync(id: "sync-7", requiredImages: ["img-a"])
            tracker.updateState { state in
                state.markImageFailed("img-a")
            }
            tracker.updateState { state in
                state.markImagesAcknowledged(["img-a"])
            }
            #expect(tracker.currentState?.failedImages.contains("img-a") == false)
        }

        @Test("incrementRetry increments retryCount by one each call")
        func incrementRetryIncrementsRetryCountByOne() {
            let tracker = SyncSessionTracker()
            tracker.startNewSync(id: "sync-8", requiredImages: [])
            for _ in 0..<3 {
                tracker.updateState { state in state.incrementRetry() }
            }
            #expect(tracker.currentState?.retryCount == 3)
        }

        @Test("missingImages is required minus acknowledged")
        func missingImagesIsRequiredMinusAcknowledged() {
            let tracker = SyncSessionTracker()
            tracker.startNewSync(id: "sync-9", requiredImages: ["a", "b", "c"])
            tracker.updateState { state in
                state.markImagesAcknowledged(["a"])
            }
            #expect(tracker.currentState?.missingImages == ["b", "c"])
        }

        @Test("isComplete requires both checklist synced and all images acknowledged")
        func isCompleteRequiresBothChecklistAndImages() {
            let tracker = SyncSessionTracker()
            tracker.startNewSync(id: "sync-10", requiredImages: ["img-a"])
            tracker.updateState { state in
                state.markImagesAcknowledged(["img-a"])
            }
            #expect(tracker.currentState?.isComplete == false)
            tracker.updateState { state in
                state.markChecklistSynced()
            }
            #expect(tracker.currentState?.isComplete == true)
        }
}
