import Foundation

struct SyncValidationResult {
    let status: String
    let progress: Double
    let missingImages: [String]
}

@MainActor
final class SyncValidationService {
    private var pendingValidation = false
    private var lastValidationTime: Date?

    private let validationThrottleInterval: TimeInterval = 15.0
    private let pendingValidationResetDelay: TimeInterval = 30.0

    func reset() {
        lastValidationTime = nil
        pendingValidation = false
    }

    func validate(
        checklistData: ChecklistData,
        transportReachable: Bool,
        imageExists: (String) -> Bool,
        requestMissingImages: ([String]) -> Void
    ) -> SyncValidationResult {
        let requiredImages = Set(
            checklistData.checklists.flatMap { checklist in
                checklist.items.compactMap { item in
                    item.imageName.isEmpty ? nil : item.imageName
                }
            }
        )

        guard !requiredImages.isEmpty else {
            return SyncValidationResult(
                status: SyncConstants.Status.complete,
                progress: 1.0,
                missingImages: []
            )
        }

        var missingImages: [String] = []
        for imageName in requiredImages where !imageExists(imageName) {
            missingImages.append(imageName)
        }

        let status: String
        if missingImages.isEmpty {
            status = SyncConstants.Status.complete
            lastValidationTime = nil
        } else if missingImages.count == requiredImages.count {
            status = SyncConstants.Status.pending
        } else {
            status = SyncConstants.Status.partial
        }

        let progress =
            Double(requiredImages.count - missingImages.count) / Double(requiredImages.count)

        guard !missingImages.isEmpty, transportReachable, !pendingValidation else {
            return SyncValidationResult(
                status: status,
                progress: progress,
                missingImages: missingImages
            )
        }

        if let lastValidation = lastValidationTime,
            Date().timeIntervalSince(lastValidation) < validationThrottleInterval
        {
            #if DEBUG
                print("Watch SyncCoordinator: Throttling validation - too soon since last request")
            #endif
            return SyncValidationResult(
                status: status,
                progress: progress,
                missingImages: missingImages
            )
        }

        #if DEBUG
            print("Watch SyncCoordinator: Validation found \(missingImages.count) missing images")
        #endif

        lastValidationTime = Date()
        pendingValidation = true
        requestMissingImages(missingImages)

        DispatchQueue.main.asyncAfter(deadline: .now() + pendingValidationResetDelay) {
            [weak self] in
            self?.pendingValidation = false
        }

        return SyncValidationResult(
            status: status,
            progress: progress,
            missingImages: missingImages
        )
    }
}
