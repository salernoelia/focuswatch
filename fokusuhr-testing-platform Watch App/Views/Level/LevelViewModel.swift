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
  }

  private func updateFromService() {
    if let progress = levelService.currentProgress {
      updateFromProgress(progress)
    }
    updateNextMilestone()
  }

  private func updateFromProgress(_ progress: LevelProgress) {
    currentLevel = progress.currentLevel
    currentXP = progress.currentXP
    xpNeeded = progress.xpNeededForNextLevel
    self.progress = progress.progressToNextLevel
  }
  
  private func updateNextMilestone() {
    let milestones = WatchConnector.shared.loadLevelData().milestones
      .filter { $0.isEnabled && $0.levelRequired > currentLevel }
      .sorted { $0.levelRequired < $1.levelRequired }
    
    nextMilestone = milestones.first
  }

  var progressPercentage: String {
    String(format: "%.0f%%", progress * 100)
  }

  var xpText: String {
    "\(currentXP) / \(xpNeeded) XP"
  }
}
