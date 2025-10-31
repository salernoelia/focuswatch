import Combine
import Foundation

class ChecklistViewModel: ObservableObject {
  @Published var checklistData = ChecklistData.default
  private var galleryManager = GalleryManager.shared
  private var lastSyncedHash: Int?

  static let shared = ChecklistViewModel()

  func saveChecklistData(silent: Bool = false) {
    do {
      let data = try JSONEncoder().encode(checklistData)
      UserDefaults.standard.set(data, forKey: "checklistData")

      if !silent {
        NotificationCenter.default.post(name: .checklistDataChanged, object: nil)
      }
    } catch {
      let appError = AppError.encodingFailed(type: "checklist data", underlying: error)
      #if DEBUG
        ErrorLogger.log(appError)
      #endif
    }
  }

  func loadChecklistData() {
    guard let data = UserDefaults.standard.data(forKey: "checklistData") else {
      return
    }

    do {
      checklistData = try JSONDecoder().decode(ChecklistData.self, from: data)
    } catch {
      let appError = AppError.decodingFailed(type: "checklist data", underlying: error)
      #if DEBUG
        ErrorLogger.log(appError)
      #endif
      checklistData = ChecklistData.default
      saveChecklistData()
    }
  }

  func updateChecklistData(from data: Data, forceOverwrite: Bool = false) {
    do {
      let newData = try JSONDecoder().decode(ChecklistData.self, from: data)
      let newHash = computeHash(for: newData)

      if let lastHash = lastSyncedHash, lastHash == newHash {
        #if DEBUG
          ErrorLogger.log("Data unchanged, skipping sync")
        #endif
        return
      }

      if forceOverwrite {
        #if DEBUG
          ErrorLogger.log("Force overwrite: Clearing old data and replacing with new data")
        #endif
        galleryManager.clearOldGalleryImages()

        DispatchQueue.main.async {
          self.checklistData = newData
          self.lastSyncedHash = newHash
          self.saveChecklistData(silent: false)
        }

        #if DEBUG
          ErrorLogger.log("Replaced with \(newData.checklists.count) checklists")
        #endif
      } else {
        DispatchQueue.main.async {
          self.checklistData = newData
          self.lastSyncedHash = newHash
          self.saveChecklistData(silent: false)
        }

        #if DEBUG
          ErrorLogger.log("Updated with \(newData.checklists.count) checklists")
        #endif
      }
    } catch {
      let appError = AppError.decodingFailed(type: "checklist data", underlying: error)
      #if DEBUG
        ErrorLogger.log(appError)
      #endif
    }
  }

  private func computeHash(for data: ChecklistData) -> Int {
    var hasher = Hasher()
    hasher.combine(data.checklists.count)
    for checklist in data.checklists {
      hasher.combine(checklist.id)
      hasher.combine(checklist.name)
      hasher.combine(checklist.items.count)
    }
    return hasher.finalize()
  }
}
