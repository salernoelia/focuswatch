import Foundation

@testable import focuswatch_watch

final class MockChecklistViewModel: ChecklistViewModel {
    private(set) var updateCalls: [(data: Data, forceOverwrite: Bool)] = []

    override func updateChecklistData(from data: Data, forceOverwrite: Bool = false) {
        updateCalls.append((data: data, forceOverwrite: forceOverwrite))
    }
}
