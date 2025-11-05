import Combine
import SwiftUI

struct LevelView: View {
  @StateObject private var viewModel = LevelViewModel()
  @State private var showingAddMilestone = false

  var body: some View {
    NavigationStack {
      List {
        currentLevelSection
        milestonesSection
      }
      .navigationTitle("Levels")
      .refreshable {
        await viewModel.refresh()
      }
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button {
            showingAddMilestone = true
          } label: {
            Text("Add Milestone")
          }
        }
      }
      .sheet(isPresented: $showingAddMilestone) {
        MilestoneEditView(viewModel: viewModel)
      }
      .onAppear {
        Task {
          await viewModel.refresh()
        }
      }
    }
  }

  private var currentLevelSection: some View {
    Section {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Text("Current Level")
            .font(.subheadline)
            .foregroundStyle(.secondary)
          Spacer()
          Text("\(viewModel.levelData.currentLevel)")
            .font(.title.bold())
        }

        VStack(alignment: .leading, spacing: 4) {
          HStack {
            Text("\(viewModel.levelData.currentXP) XP")
              .font(.caption)
              .foregroundStyle(.secondary)
            Spacer()
            Text("\(viewModel.xpNeededForNext) XP")
              .font(.caption)
              .foregroundStyle(.secondary)
          }

          ProgressView(value: viewModel.progress)
            .tint(.blue)
        }

        Text("Total: \(viewModel.levelData.totalXP) XP")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .padding(.vertical, 4)
    }
  }

  private var milestonesSection: some View {
    Section("Milestones") {
      if viewModel.levelData.milestones.isEmpty {
        Text("No milestones configured")
          .foregroundStyle(.secondary)
      } else {
        ForEach(viewModel.sortedMilestones) { milestone in
          NavigationLink(
            destination: MilestoneDetailView(milestone: milestone, viewModel: viewModel)
          ) {
            MilestoneRow(milestone: milestone, currentLevel: viewModel.levelData.currentLevel)
          }
        }
        .onDelete(perform: viewModel.deleteMilestone)
      }
    }
  }
}

struct MilestoneRow: View {
  let milestone: LevelMilestone
  let currentLevel: Int

  private var isUnlocked: Bool {
    currentLevel >= milestone.levelRequired
  }

  var body: some View {
    HStack(spacing: 12) {
      Text("\(milestone.levelRequired)")
        .font(.title3.bold())
        .foregroundStyle(isUnlocked ? .blue : .secondary)
        .frame(width: 40)

      VStack(alignment: .leading, spacing: 2) {
        Text(milestone.title)
          .font(.body)

        if !milestone.description.isEmpty {
          Text(milestone.description)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      Spacer()

      if isUnlocked {
        Image(systemName: "checkmark.circle.fill")
          .foregroundStyle(.blue)
      }
    }
    .opacity(milestone.isEnabled ? 1.0 : 0.5)
  }
}

@MainActor
class LevelViewModel: ObservableObject {
  @Published var levelData: LevelData

  private let watchConnector = WatchConnector.shared
  private var cancellables = Set<AnyCancellable>()

  init() {
    self.levelData = watchConnector.loadLevelData()
    setupObservers()
  }

  private func setupObservers() {
    NotificationCenter.default.publisher(for: NSNotification.Name("LevelDataUpdated"))
      .sink { [weak self] notification in
        if let updatedData = notification.userInfo?["levelData"] as? LevelData {
          self?.levelData = updatedData
          self?.objectWillChange.send()
        } else {
          self?.levelData = self?.watchConnector.loadLevelData() ?? LevelData.default
          self?.objectWillChange.send()
        }
      }
      .store(in: &cancellables)
  }

  var sortedMilestones: [LevelMilestone] {
    levelData.milestones.sorted { $0.levelRequired < $1.levelRequired }
  }

  var progress: Double {
    let xpForNext = (levelData.currentLevel + 1) * 100
    return Double(levelData.currentXP) / Double(xpForNext)
  }

  var xpNeededForNext: Int {
    (levelData.currentLevel + 1) * 100
  }

  func addMilestone(_ milestone: LevelMilestone) {
    levelData.milestones.append(milestone)
    save()
  }

  func updateMilestone(_ milestone: LevelMilestone) {
    if let index = levelData.milestones.firstIndex(where: { $0.id == milestone.id }) {
      levelData.milestones[index] = milestone
      save()
    }
  }

  func deleteMilestone(at offsets: IndexSet) {
    let sorted = sortedMilestones
    offsets.forEach { index in
      if let milestoneIndex = levelData.milestones.firstIndex(where: { $0.id == sorted[index].id })
      {
        levelData.milestones.remove(at: milestoneIndex)
      }
    }
    save()
  }

  private func save() {
    #if DEBUG
      print("💾 iOS: LevelViewModel saving changes")
    #endif
    watchConnector.saveLevelData(levelData)
    watchConnector.syncLevelToWatch()
    objectWillChange.send()
  }

  func refresh() async {
    #if DEBUG
      print("🔄 iOS: LevelViewModel refreshing")
    #endif
    levelData = watchConnector.loadLevelData()
    watchConnector.syncLevelToWatch()
    objectWillChange.send()
  }
}

#Preview {
  LevelView()
}
