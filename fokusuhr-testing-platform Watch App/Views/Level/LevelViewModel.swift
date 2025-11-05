import Combine
import Foundation

@MainActor
class LevelViewModel: ObservableObject {
  static let shared = LevelViewModel()

  @Published var currentLevel: Int = 1
  @Published var currentXP: Int = 0
  @Published var xpNeeded: Int = 200
  @Published var progress: Double = 0
  @Published var nextMilestone: LevelMilestone?
  @Published var milestones: [LevelMilestone] = []

  private var cancellables = Set<AnyCancellable>()
  private let levelService = LevelService.shared

  private init() {
    setupObservers()
    updateFromService()
  }

  private func setupObservers() {
    levelService.objectWillChange
      .sink { [weak self] _ in
        self?.updateFromService()
      }
      .store(in: &cancellables)

    NotificationCenter.default.publisher(for: NSNotification.Name("LevelMilestonesUpdated"))
      .sink { [weak self] _ in
        self?.updateMilestones()
      }
      .store(in: &cancellables)
  }

  private func updateFromService() {
    if let progress = levelService.currentProgress {
      updateFromProgress(progress)
    }
    updateMilestones()
  }

  private func updateFromProgress(_ progress: LevelProgress) {
    currentLevel = progress.currentLevel
    currentXP = progress.currentXP
    xpNeeded = progress.xpNeededForNextLevel
    self.progress = progress.progressToNextLevel
  }

  private func updateMilestones() {
    let allMilestones = loadLevelMilestones()
      .sorted { $0.levelRequired < $1.levelRequired }

    milestones = allMilestones

    nextMilestone =
      allMilestones
      .filter { $0.isEnabled && $0.levelRequired > currentLevel }
      .first
  }

  private func loadLevelMilestones() -> [LevelMilestone] {
    guard let data = UserDefaults.standard.data(forKey: "levelMilestones") else {
      return []
    }

    do {
      return try JSONDecoder().decode([LevelMilestone].self, from: data)
    } catch {
      #if DEBUG
        ErrorLogger.log(AppError.decodingFailed(type: "level milestones", underlying: error))
      #endif
      return []
    }
  }

  var progressPercentage: String {
    String(format: "%.0f%%", progress * 100)
  }

  var xpText: String {
    "\(currentXP) / \(xpNeeded) XP"
  }

  func syncFromiOS() async {
    let connector = WatchConnector()
    let milestones = connector.loadLevelMilestones()
    if !milestones.isEmpty {
      await MainActor.run {
        updateMilestones()
      }
    }
  }
}
