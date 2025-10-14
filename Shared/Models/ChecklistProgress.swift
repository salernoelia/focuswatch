import Foundation

struct ChecklistProgress: Codable {
  var checklistId: UUID
  var collectedItemIds: [UUID]
  var currentIndex: Int

  init(checklistId: UUID, collectedItemIds: [UUID] = [], currentIndex: Int = 0) {
    self.checklistId = checklistId
    self.collectedItemIds = collectedItemIds
    self.currentIndex = currentIndex
  }
}

class ChecklistProgressManager {
  static let shared = ChecklistProgressManager()

  private let storageKey = "checklistProgress"

  func saveProgress(for checklistId: UUID, collectedItemIds: [UUID], currentIndex: Int) {
    var allProgress = loadAllProgress()
    allProgress[checklistId.uuidString] = ChecklistProgress(
      checklistId: checklistId,
      collectedItemIds: collectedItemIds,
      currentIndex: currentIndex
    )

    if let encoded = try? JSONEncoder().encode(allProgress) {
      UserDefaults.standard.set(encoded, forKey: storageKey)
    }
  }

  func loadProgress(for checklistId: UUID) -> ChecklistProgress? {
    let allProgress = loadAllProgress()
    return allProgress[checklistId.uuidString]
  }

  func clearProgress(for checklistId: UUID) {
    var allProgress = loadAllProgress()
    allProgress.removeValue(forKey: checklistId.uuidString)

    if let encoded = try? JSONEncoder().encode(allProgress) {
      UserDefaults.standard.set(encoded, forKey: storageKey)
    }
  }

  private func loadAllProgress() -> [String: ChecklistProgress] {
    guard let data = UserDefaults.standard.data(forKey: storageKey),
      let decoded = try? JSONDecoder().decode([String: ChecklistProgress].self, from: data)
    else {
      return [:]
    }
    return decoded
  }
}
