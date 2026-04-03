import Foundation
import Testing

#if canImport(companion)
    @testable import companion
#elseif canImport(shared)
    @testable import shared
#endif

#if canImport(companion) || canImport(shared)
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
    }
#endif
