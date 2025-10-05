import Foundation
import SwiftData

@MainActor
class ModelContainerProvider {
    static let shared = ModelContainerProvider()
    
    let container: ModelContainer
    
    private init() {
        let schema = Schema([
            ChecklistModel.self,
            ChecklistItemModel.self,
            GalleryItemModel.self,
            CalendarEventModel.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
