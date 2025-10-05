import Foundation

class ChecklistManager {
    @Published var checklistData = ChecklistData.default
    private var galleryManager = GalleryManager.shared

    static let shared = ChecklistManager()

    func saveChecklistData() {
        do {
            let data = try JSONEncoder().encode(checklistData)
            UserDefaults.standard.set(data, forKey: "checklistData")
        } catch {
            print("Error saving checklist data: \(error.localizedDescription)")
        }
    }

    func loadChecklistData() {
        guard let data = UserDefaults.standard.data(forKey: "checklistData")
        else {
            return
        }

        do {
            checklistData = try JSONDecoder().decode(
                ChecklistData.self, from: data)
        } catch {
            print("Error loading checklist data: \(error.localizedDescription)")
            checklistData = ChecklistData.default
            saveChecklistData()
        }
    }

    func updateChecklistData(
        from data: Data, forceOverwrite: Bool = false
    ) {
        do {
            let newData = try JSONDecoder().decode(
                ChecklistData.self, from: data)

            if forceOverwrite {
                print(
                    "Force overwrite: Clearing old data and replacing with new data"
                )
                galleryManager.clearOldGalleryImages()
                checklistData = newData
                print("Replaced with \(newData.checklists.count) checklists")
            } else {

                checklistData = newData
                print("Updated with \(newData.checklists.count) checklists")
            }

            saveChecklistData()
        } catch {
            print(
                "Error decoding checklist data: \(error.localizedDescription)")
        }
    }
}
