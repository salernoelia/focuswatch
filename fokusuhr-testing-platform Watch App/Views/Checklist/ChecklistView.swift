import SwiftUI

protocol ChecklistItemProtocol: Identifiable {
  var id: UUID { get }
  var title: String { get }
  var imageName: String { get }
}

extension ChecklistItem: ChecklistItemProtocol {}

enum ChecklistState {
  case description
  case instructions
  case resumePrompt
  case checklist
  case completed
}

struct UniversalChecklistView<Item: ChecklistItemProtocol>: View {
  let title: String
  let description: String
  let instructionTitle: String
  let items: [Item]
  let checklistId: UUID

  @EnvironmentObject var watchConnector: WatchConnector
  @State private var remainingItems: [Item] = []
  @State private var collectedItems: [Item] = []
  @State private var currentIndex = 0
  @State private var state: ChecklistState = .description
  @State private var hasExistingProgress = false

  private let progressManager = ChecklistProgressManager.shared
  private let telemetryManager = TelemetryManager.shared
  private let appLogger = AppLogger.shared
  private var appName: String {
    TelemetryManager.appName(from: title)
  }

  var body: some View {
    switch state {
    case .description:
      ChecklistDescriptionView(
        title: title,
        description: description,
        onContinue: {
          state = .instructions
        }
      )
      .transition(.opacity)
    case .instructions:
      ChecklistInstructionsView(
        title: instructionTitle,
        onStart: {
          checkAndLoadProgress()
        }
      )
      .transition(.opacity)
      .onAppear {
        checkForExistingProgress()
        // Log when instructions view appears
        logEventSafely(eventType: "instructions_viewed")
      }
    case .resumePrompt:
      ChecklistResumePromptView(
        onResume: {
          state = .checklist
        },
        onRestart: {
          progressManager.clearProgress(for: checklistId)
          remainingItems = items
          collectedItems = []
          currentIndex = 0
          state = .checklist
        }
      )
      .transition(.opacity)
    case .checklist:
      ChecklistMainView(
        remainingItems: $remainingItems,
        collectedItems: $collectedItems,
        currentIndex: $currentIndex,
        totalItems: items.count,
        onComplete: {
          progressManager.clearProgress(for: checklistId)
          state = .completed
        }
      )
      .onDisappear {
        if state == .checklist {
          saveProgress()
          // Log app closed event safely
          logEventSafely(eventType: "app_closed")
        }
      }
    case .completed:
      ChecklistCompletionView()
        .transition(.opacity)
    }
  }

  private func checkForExistingProgress() {
    guard !items.isEmpty else { return }
    
    if let progress = progressManager.loadProgress(for: checklistId) {
      let collectedIds = Set(progress.collectedItemIds)
      let remaining = items.filter { !collectedIds.contains($0.id) }

      if !remaining.isEmpty && !collectedIds.isEmpty {
        collectedItems = items.filter { collectedIds.contains($0.id) }
        remainingItems = remaining
        // Safe bounds checking for currentIndex
        currentIndex = max(0, min(progress.currentIndex, remainingItems.count - 1))
        state = .resumePrompt
      }
    }
  }

  private func checkAndLoadProgress() {
    // Guard against empty items array to prevent crashes
    guard !items.isEmpty else {
      #if DEBUG
      print("Warning: Checklist has no items, cannot start")
      #endif
      return
    }
    
    if let progress = progressManager.loadProgress(for: checklistId) {
      let collectedIds = Set(progress.collectedItemIds)
      collectedItems = items.filter { collectedIds.contains($0.id) }
      remainingItems = items.filter { !collectedIds.contains($0.id) }
      
      // Safe bounds checking for currentIndex
      if remainingItems.isEmpty {
        remainingItems = items
        collectedItems = []
        currentIndex = 0
      } else {
        currentIndex = max(0, min(progress.currentIndex, remainingItems.count - 1))
      }
    } else {
      remainingItems = items
      collectedItems = []
      currentIndex = 0
    }
    
    // Log app opened event safely
    logEventSafely(eventType: "app_opened")
    
    state = .checklist
  }

  private func saveProgress() {
    let collectedIds = collectedItems.map { $0.id }
    progressManager.saveProgress(
      for: checklistId,
      collectedItemIds: collectedIds,
      currentIndex: currentIndex
    )
  }
  
  /// Safely log events without crashing the app
  private func logEventSafely(eventType: String) {
    guard telemetryManager.hasConsent else { return }
    
    // Capture values needed for logging to avoid retaining self
    let appNameForLogging = appName
    let hasConsent = telemetryManager.hasConsent
    
    // Run logging in a background task to ensure it never crashes the app
    Task { @MainActor in
      // Double-check consent
      guard hasConsent, telemetryManager.hasConsent else { return }
      
      // Safely get watch ID
      let watchId = TelemetryManager.watchId()
      
      // Safely prepare telemetry data
      guard let data = telemetryManager.prepareTelemetryData(eventType: eventType) else {
        return
      }
      
      // Log the event - wrap in additional error handling for extra safety
      do {
        await appLogger.logEvent(appName: appNameForLogging, watchId: watchId, data: data)
      } catch {
        // Silently fail - logging should never crash the app
        #if DEBUG
        print("Failed to log checklist event: \(error.localizedDescription)")
        #endif
      }
    }
  }
}
