import Foundation

struct ChecklistProgress: Codable {
  var checklistId: UUID
  var collectedItemIds: [UUID]
  var currentIndex: Int
  var updatedAt: Date

  init(checklistId: UUID, collectedItemIds: [UUID] = [], currentIndex: Int = 0, updatedAt: Date = Date()) {
    self.checklistId = checklistId
    self.collectedItemIds = collectedItemIds
    self.currentIndex = currentIndex
    self.updatedAt = updatedAt
  }

  enum CodingKeys: String, CodingKey {
    case checklistId
    case collectedItemIds
    case currentIndex
    case updatedAt
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    checklistId = try container.decode(UUID.self, forKey: .checklistId)
    collectedItemIds = try container.decodeIfPresent([UUID].self, forKey: .collectedItemIds) ?? []
    currentIndex = try container.decodeIfPresent(Int.self, forKey: .currentIndex) ?? 0
    updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
  }
}

class ChecklistProgressManager {
  static let shared = ChecklistProgressManager()

  private let storageKey = "checklistProgress"
  private let completionStorageKey = "checklistCompletion"

  func saveProgress(for checklistId: UUID, collectedItemIds: [UUID], currentIndex: Int) {
    var allProgress = loadAllProgress()
    allProgress[checklistId.uuidString] = ChecklistProgress(
      checklistId: checklistId,
      collectedItemIds: collectedItemIds,
      currentIndex: currentIndex,
      updatedAt: Date()
    )

    if let encoded = try? JSONEncoder().encode(allProgress) {
      UserDefaults.standard.set(encoded, forKey: storageKey)
    }
  }

  func loadProgress(for checklistId: UUID) -> ChecklistProgress? {
    let allProgress = loadAllProgress()
    return allProgress[checklistId.uuidString]
  }

  func loadProgress(for checklistId: UUID, resetConfiguration: ChecklistResetConfiguration) -> ChecklistProgress? {
    guard let progress = loadProgress(for: checklistId) else {
      return nil
    }

    guard shouldReset(progress: progress, configuration: resetConfiguration) else {
      return progress
    }

    clearProgress(for: checklistId)
    return nil
  }

  func clearProgress(for checklistId: UUID) {
    var allProgress = loadAllProgress()
    allProgress.removeValue(forKey: checklistId.uuidString)

    if let encoded = try? JSONEncoder().encode(allProgress) {
      UserDefaults.standard.set(encoded, forKey: storageKey)
    }
  }

  func markCompleted(for checklistId: UUID) {
    var allCompletions = loadAllCompletions()
    allCompletions[checklistId.uuidString] = Date()
    if let encoded = try? JSONEncoder().encode(allCompletions) {
      UserDefaults.standard.set(encoded, forKey: completionStorageKey)
    }
  }

  func clearCompletion(for checklistId: UUID) {
    var allCompletions = loadAllCompletions()
    allCompletions.removeValue(forKey: checklistId.uuidString)
    if let encoded = try? JSONEncoder().encode(allCompletions) {
      UserDefaults.standard.set(encoded, forKey: completionStorageKey)
    }
  }

  func clearProgressAndCompletion(for checklistId: UUID) {
    clearProgress(for: checklistId)
    clearCompletion(for: checklistId)
  }

  func nextAvailableDate(for checklistId: UUID, resetConfiguration: ChecklistResetConfiguration) -> Date? {
    guard resetConfiguration.interval != .none else {
      clearCompletion(for: checklistId)
      return nil
    }

    let allCompletions = loadAllCompletions()
    guard let completedAt = allCompletions[checklistId.uuidString] else {
      return nil
    }

    guard let resetDate = nextResetDate(after: completedAt, configuration: resetConfiguration) else {
      return nil
    }

    if Date() >= resetDate {
      clearCompletion(for: checklistId)
      return nil
    }

    return resetDate
  }

  func isCompletionLocked(for checklistId: UUID, resetConfiguration: ChecklistResetConfiguration) -> Bool {
    nextAvailableDate(for: checklistId, resetConfiguration: resetConfiguration) != nil
  }

  private func loadAllProgress() -> [String: ChecklistProgress] {
    guard let data = UserDefaults.standard.data(forKey: storageKey),
      let decoded = try? JSONDecoder().decode([String: ChecklistProgress].self, from: data)
    else {
      return [:]
    }
    return decoded
  }

  private func loadAllCompletions() -> [String: Date] {
    guard let data = UserDefaults.standard.data(forKey: completionStorageKey),
      let decoded = try? JSONDecoder().decode([String: Date].self, from: data)
    else {
      return [:]
    }
    return decoded
  }

  private func shouldReset(progress: ChecklistProgress, configuration: ChecklistResetConfiguration) -> Bool {
    switch configuration.interval {
    case .none:
      return false
    case .daily:
      return hasCrossedScheduledReset(
        since: progress.updatedAt,
        hour: configuration.hour,
        minute: configuration.minute,
        weekday: nil
      )
    case .weekly:
      return hasCrossedScheduledReset(
        since: progress.updatedAt,
        hour: configuration.hour,
        minute: configuration.minute,
        weekday: configuration.weekday
      )
    }
  }

  private func hasCrossedScheduledReset(
    since lastUpdate: Date,
    hour: Int,
    minute: Int,
    weekday: Int?
  ) -> Bool {
    let calendar = Calendar.current
    let now = Date()

    var components = DateComponents()
    components.hour = hour
    components.minute = minute
    if let weekday {
      components.weekday = weekday
    }

    guard
      let mostRecentReset = calendar.nextDate(
        after: now,
        matching: components,
        matchingPolicy: .nextTime,
        direction: .backward
      )
    else {
      return false
    }

    return lastUpdate < mostRecentReset
  }

  private func nextResetDate(after completionDate: Date, configuration: ChecklistResetConfiguration) -> Date? {
    let calendar = Calendar.current
    var components = DateComponents()
    components.hour = configuration.hour
    components.minute = configuration.minute
    if configuration.interval == .weekly {
      components.weekday = configuration.weekday
    }

    return calendar.nextDate(
      after: completionDate,
      matching: components,
      matchingPolicy: .nextTime,
      direction: .forward
    )
  }
}
