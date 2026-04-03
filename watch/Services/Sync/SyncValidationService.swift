import Foundation

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
    ) -> String {
        let requiredImages = Set(
            checklistData.checklists.flatMap { checklist in
                checklist.items.compactMap { item in
                    item.imageName.isEmpty ? nil : item.imageName
                }
            }
        )

        guard !requiredImages.isEmpty else {
            return SyncConstants.Status.complete
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

        guard !missingImages.isEmpty, transportReachable, !pendingValidation else {
            return status
        }

        if let lastValidation = lastValidationTime,
            Date().timeIntervalSince(lastValidation) < validationThrottleInterval
        {
            #if DEBUG
                print("Watch SyncCoordinator: Throttling validation - too soon since last request")
            #endif
            return status
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

        return status
    }
}
