import SwiftUI
import SwiftData

struct CompanionView: View {
    @Environment(WatchConnector.self) private var watchConnector
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var checklistManager: ChecklistManager
    @StateObject private var galleryStorage: GalleryStorage
    @StateObject private var calendarViewModel: CalendarViewModel
    
    init() {
        let context = ModelContainerProvider.shared.container.mainContext
        let connector = WatchConnector()
        
        _checklistManager = StateObject(wrappedValue: ChecklistManager(modelContext: context, watchConnector: connector))
        _galleryStorage = StateObject(wrappedValue: GalleryStorage(modelContext: context))
        _calendarViewModel = StateObject(wrappedValue: CalendarViewModel(modelContext: context))
    }
    
    var body: some View {
        TabView {
            WizardView()
                .environmentObject(watchConnector)
                .tabItem {
                    Image(systemName: "wand.and.rays")
                    Text("Wizard")
                }

            GalleryView()
                .environmentObject(galleryStorage)
                .tabItem {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("Gallery")
                }
            
            CalendarView()
                .environmentObject(calendarViewModel)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }

            JournalView()
                .tabItem {
                    Image(systemName: "book")
                    Text("Journal")
                }

            SettingsView()
                .environmentObject(checklistManager)
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
        }
    }
}
