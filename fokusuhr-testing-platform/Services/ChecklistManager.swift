import Foundation
import SwiftUI

class ChecklistManager: ObservableObject {
    @Published var data: ChecklistData
    var watchConnector: WatchConnector
    
    init(watchConnector: WatchConnector) {
        self.watchConnector = watchConnector
        self.data = Self.loadSharedData()
        watchConnector.checklistData = self.data
    }
    
    static func loadSharedData() -> ChecklistData {
        let loadedData = UserDefaults.standard.data(forKey: "checklistData")
        if let loadedData = loadedData,
           let decoded = try? JSONDecoder().decode(ChecklistData.self, from: loadedData) {
            return decoded
        } else {
            let defaultData = ChecklistData.default
            if let encoded = try? JSONEncoder().encode(defaultData) {
                UserDefaults.standard.set(encoded, forKey: "checklistData")
            }
            return defaultData
        }
    }
    
    func addChecklist(name: String) {
        data.checklists.append(Checklist(name: name))
        saveData()
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
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: "checklistData")
        }
        watchConnector.checklistData = data
        watchConnector.forceSyncToWatch()
    }
    
    private func loadData() -> ChecklistData {
        guard let data = UserDefaults.standard.data(forKey: "checklistData"),
              let decoded = try? JSONDecoder().decode(ChecklistData.self, from: data) else {
            return ChecklistData.default
        }
        return decoded
    }
}
