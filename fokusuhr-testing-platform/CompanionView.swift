import SwiftUI

struct CompanionView: View {
    @EnvironmentObject private var watchConnector: WatchConnector
    @StateObject private var checklistManager = ChecklistViewModel(
        watchConnector: WatchConnector.shared
    )

    var body: some View {
        TabView {
            WizardView()
                .environmentObject(watchConnector)
                .tabItem {
                    Image(systemName: "wand.and.rays")
                    Text("Wizard")
                }

            ChecklistEditorView(checklistManager: checklistManager)
                .tabItem {
                    Image(systemName: "checklist")
                    Text("Checklists")
                }

            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Kalender")
                }

            LevelView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Levels")
                }

            GalleryView()
                .tabItem {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("Photos")
                }

            FeedbackView()
                .tabItem {
                    Image(systemName: "book")
                    Text("Feedback")
                }

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Einstellungen")
                }
        }
    }
}

#Preview {
    CompanionView()
}
