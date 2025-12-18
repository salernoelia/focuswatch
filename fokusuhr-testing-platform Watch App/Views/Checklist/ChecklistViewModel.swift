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
                NotificationCenter.default.post(name: Notification.Name.checklistDataChanged, object: nil)
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

            if !forceOverwrite {
                if let lastHash = lastSyncedHash, lastHash == newHash {
                    #if DEBUG
                        ErrorLogger.log("Watch: Data unchanged (hash: \(newHash)), skipping update")
                    #endif
                    return
                }
            }

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.checklistData = newData
                self.lastSyncedHash = newHash
                self.saveChecklistData(silent: false)

                #if DEBUG
                    ErrorLogger.log("Watch: Updated with \(newData.checklists.count) checklists (forceOverwrite: \(forceOverwrite), hash: \(newHash))")
                    for checklist in newData.checklists {
                        ErrorLogger.log("  - \(checklist.name): \(checklist.items.count) items")
                    }
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
            hasher.combine(checklist.xpReward)
            for item in checklist.items {
                hasher.combine(item.id)
                hasher.combine(item.title)
                hasher.combine(item.imageName)
            }
        }
        return hasher.finalize()
    }
}
