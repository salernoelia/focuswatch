import Combine
import Foundation
import SwiftUI

class AppsManager: ObservableObject {
  @Published var apps: [AppInfo] = []
  @Published var isLoading = false
  @Published var lastError: AppError?

  private(set) var builtInAppCount: Int = 0

  static let shared = AppsManager()

  private var cancellables = Set<AnyCancellable>()

  private init() {
    loadApps()
    observeChecklistChanges()
  }

  private func observeChecklistChanges() {
    NotificationCenter.default.publisher(for: .checklistDataChanged)
      .sink { [weak self] _ in
        self?.loadApps()
      }
      .store(in: &cancellables)
  }

  func loadApps() {
    isLoading = true
    lastError = nil

    apps = buildAppsList()
    isLoading = false
  }

  private func buildAppsList() -> [AppInfo] {
    var appsList: [AppInfo] = []
    var currentIndex = 0

    let builtInApps = [
      ("Tachometer", "Wie fühlst du dich gerade?", Color.yellow),
      ("Schreiben", "Fokushilfe beim Schreiben.", Color.blue),
      ("Pomodoro", "Timer zur Zeiteinteilung", Color.red),
      ("Fidget", "Interaktives Vibrationsspielzeug", Color.gray),
      ("Farbatmung", "Beruhigende Atemübungen", Color.green),
      ("Kalender", "Routineaufgaben und Termine", Color.purple),
    ]

    builtInAppCount = builtInApps.count

    for (title, description, color) in builtInApps {
      appsList.append(
        AppInfo(
          title: title,
          description: description,
          color: color,
          index: currentIndex
        ))
      currentIndex += 1
    }

    let checklistData = loadChecklistData()
    for checklist in checklistData.checklists {
      appsList.append(
        AppInfo(
          title: checklist.name,
          description: "Interaktive Checkliste",
          color: .blue,
          index: currentIndex
        ))
      currentIndex += 1
    }

    return appsList
  }

  private func loadChecklistData() -> ChecklistData {
    guard let data = UserDefaults.standard.data(forKey: "checklistData") else {
      return ChecklistData.default
    }

    do {
      return try JSONDecoder().decode(ChecklistData.self, from: data)
    } catch {
      let appError = AppError.decodingFailed(type: "checklist data", underlying: error)
      #if DEBUG
        ErrorLogger.log(appError)
      #endif
      lastError = appError
      return ChecklistData.default
    }
  }

  func refreshApps() {
    loadApps()
  }
}

extension Notification.Name {
  static let checklistDataChanged = Notification.Name("checklistDataChanged")
}
