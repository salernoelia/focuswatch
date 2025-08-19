import Foundation
import SwiftUI

class ChecklistManager: ObservableObject {
    @Published var configuration: ChecklistConfiguration
    private let watchConnector: WatchConnector
    
    init(watchConnector: WatchConnector) {
        self.watchConnector = watchConnector
        self.configuration = watchConnector.checklistConfiguration
    }
    
    func addChecklistType(name: String, displayName: String, color: Color) {
        let newType = ChecklistType(
            name: name,
            displayName: displayName,
            items: [],
            color: color
        )
        configuration.checklistTypes.append(newType)
        updateConfiguration()
    }
    
    func updateChecklistType(_ type: ChecklistType) {
        if let index = configuration.checklistTypes.firstIndex(where: { $0.id == type.id }) {
            configuration.checklistTypes[index] = type
            updateConfiguration()
        }
    }
    
    func deleteChecklistType(_ type: ChecklistType) {
        configuration.checklistTypes.removeAll { $0.id == type.id }
        updateConfiguration()
    }
    
    func addImageName(_ imageName: String) {
        if !configuration.availableImages.contains(imageName) {
            configuration.availableImages.append(imageName)
            updateConfiguration()
        }
    }
    
    func removeImageName(_ imageName: String) {
        configuration.availableImages.removeAll { $0 == imageName }
        updateConfiguration()
    }
    
    private func updateConfiguration() {
        watchConnector.updateChecklistConfiguration(configuration)
    }
}
