import Combine
import Foundation
import SwiftUI

class AppsManager: ObservableObject {
  @Published var apps: [AppInfo] = []
  @Published var isLoading = false
  @Published var lastError: AppError?

  static let shared = AppsManager()

  private init() {
    Task {
      await fetchApps()
    }
  }

  func fetchApps() async {
    await MainActor.run {
      isLoading = true
      lastError = nil
    }

    await MainActor.run {
      apps = buildAppsList()
      isLoading = false
    }
  }

  private func buildAppsList() -> [AppInfo] {
    var appsList: [AppInfo] = []
    var currentIndex = 0

    let builtInApps = [
      ("Tachometer", "Gefühlsanzeige", Color.yellow),
      ("Farbatmung", "Beruhigende Atemübungen", Color.green),
      //("Fidget Spinner", "Digitaler Fidget Spinner", Color.orange),
      ("Anne (Beta)", "Virtueller Assistent", Color.red),
    ]

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

    let checklistData = ChecklistManager.loadSharedData()
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

  func refreshApps() {
    Task {
      await fetchApps()
    }
  }

  private func getDefaultApps() -> [AppInfo] {
    var apps = [
      AppInfo(title: "Farbatmung", description: "Beruhigende Atemübungen", color: .green, index: 0)
      // AppInfo(title: "Fidget Spinner", description: "Digitaler Fidget Spinner", color: .orange, index: 1)
    ]

    let checklistData = ChecklistManager.loadSharedData()
    for (index, checklist) in checklistData.checklists.enumerated() {
      apps.append(
        AppInfo(
          title: checklist.name, description: "Interaktive Checkliste", color: .blue,
          index: index + 2))
    }

    return apps
  }
}
