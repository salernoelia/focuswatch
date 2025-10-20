import Combine
import Foundation

class ChecklistManager: ObservableObject {
  @Published var checklistData = ChecklistData.default
  private var galleryManager = GalleryManager.shared

  static let shared = ChecklistManager()

  func saveChecklistData() {
    do {
      let data = try JSONEncoder().encode(checklistData)
      UserDefaults.standard.set(data, forKey: "checklistData")

      NotificationCenter.default.post(name: .checklistDataChanged, object: nil)
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

      if forceOverwrite {
        #if DEBUG
          ErrorLogger.log("Force overwrite: Clearing old data and replacing with new data")
        #endif
        galleryManager.clearOldGalleryImages()

        DispatchQueue.main.async {
          self.checklistData = newData
          self.saveChecklistData()
        }

        #if DEBUG
          ErrorLogger.log("Replaced with \(newData.checklists.count) checklists")
        #endif
      } else {
        DispatchQueue.main.async {
          self.checklistData = newData
          self.saveChecklistData()
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
}
