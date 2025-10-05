import Foundation
import SwiftUI
import SwiftData

@MainActor
class ChecklistManager: ObservableObject {
    private let modelContext: ModelContext
    var watchConnector: WatchConnector
    
    @Published var checklists: [ChecklistModel] = []
    
    init(modelContext: ModelContext, watchConnector: WatchConnector) {
        self.modelContext = modelContext
        self.watchConnector = watchConnector
        fetchChecklists()
        ensureDefaultChecklists()
    }
    
    private func fetchChecklists() {
        let descriptor = FetchDescriptor<ChecklistModel>(
            sortBy: [SortDescriptor(\.name)]
        )
        
        do {
            checklists = try modelContext.fetch(descriptor)
        } catch {
            #if DEBUG
            ErrorLogger.log(.databaseQueryFailed(operation: "fetch checklists", underlying: error))
            #endif
            checklists = []
        }
    }
    
    private func ensureDefaultChecklists() {
        guard checklists.isEmpty else { return }
        
        let defaultChecklists = ChecklistData.getDefault()
        for checklist in defaultChecklists {
            modelContext.insert(checklist)
        }
        
        saveChanges()
    }
    
    func addChecklist(name: String) {
        let checklist = ChecklistModel(name: name)
        modelContext.insert(checklist)
        saveChanges()
    }
    
    func deleteChecklist(_ checklist: ChecklistModel) {
        modelContext.delete(checklist)
        saveChanges()
    }
    
    func updateChecklist(_ checklist: ChecklistModel) {
        saveChanges()
    }
    
    func addItem(to checklist: ChecklistModel, title: String, imageName: String = "") {
        let item = ChecklistItemModel(title: title, imageName: imageName)
        item.checklist = checklist
        checklist.items.append(item)
        modelContext.insert(item)
        saveChanges()
    }
    
    func deleteItem(_ item: ChecklistItemModel) {
        modelContext.delete(item)
        saveChanges()
    }
    
    private func saveChanges() {
        do {
            try modelContext.save()
            fetchChecklists()
            syncToWatch()
        } catch {
            #if DEBUG
            ErrorLogger.log(.databaseQueryFailed(operation: "save checklists", underlying: error))
            #endif
        }
    }
    
    private func syncToWatch() {
        let data = ChecklistData(from: checklists)
        watchConnector.checklistData = data
        watchConnector.forceSyncToWatch()
    }
}
