import Foundation
import SwiftUI

class ChecklistViewModel: ObservableObject {
  @Published var data: ChecklistData
  @Published var lastError: AppError?
  var watchConnector: WatchConnector

  init(watchConnector: WatchConnector) {
    self.watchConnector = watchConnector
    self.data = Self.loadSharedData()
    watchConnector.checklistData = self.data
  }

  static func loadSharedData() -> ChecklistData {
    guard let loadedData = UserDefaults.standard.data(forKey: "checklistData") else {
      let defaultData = ChecklistData.default
      if let encoded = try? JSONEncoder().encode(defaultData) {
        UserDefaults.standard.set(encoded, forKey: "checklistData")
      }
      return defaultData
    }

    do {
      return try JSONDecoder().decode(ChecklistData.self, from: loadedData)
    } catch {
      let appError = AppError.decodingFailed(type: "checklist data", underlying: error)
      #if DEBUG
        ErrorLogger.log(appError)
      #endif
      let defaultData = ChecklistData.default
      if let encoded = try? JSONEncoder().encode(defaultData) {
        UserDefaults.standard.set(encoded, forKey: "checklistData")
      }
      return defaultData
    }
  }

  func addChecklist(name: String) -> Checklist {
    let newChecklist = Checklist(name: name)
    data.checklists.append(newChecklist)
    saveData()
    return newChecklist
  }

  func deleteChecklist(_ checklist: Checklist) {
    data.checklists.removeAll { $0.id == checklist.id }
    saveData()
  }

  func updateChecklist(_ checklist: Checklist) {
    if let index = data.checklists.firstIndex(where: { $0.id == checklist.id }) {
      data.checklists[index] = checklist
      saveData()
    }
  }

  func addItem(to checklist: Checklist, title: String, imageName: String = "") {
    if let index = data.checklists.firstIndex(where: { $0.id == checklist.id }) {
      data.checklists[index].items.append(ChecklistItem(title: title, imageName: imageName))
      saveData()
    }
  }

  func deleteItem(from checklist: Checklist, item: ChecklistItem) {
    if let checklistIndex = data.checklists.firstIndex(where: { $0.id == checklist.id }) {
      data.checklists[checklistIndex].items.removeAll { $0.id == item.id }
      saveData()
    }
  }

  private func saveData() {
    do {
      let encoded = try JSONEncoder().encode(data)
      UserDefaults.standard.set(encoded, forKey: "checklistData")
      watchConnector.checklistData = data
      watchConnector.forceSyncToWatch()

      NotificationCenter.default.post(name: .checklistDataChanged, object: nil)
    } catch {
      let appError = AppError.encodingFailed(type: "checklist data", underlying: error)
      #if DEBUG
        ErrorLogger.log(appError)
      #endif
      lastError = appError
    }
  }

  private func loadData() -> ChecklistData {
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
}
