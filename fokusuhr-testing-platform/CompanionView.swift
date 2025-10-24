import SwiftUI

struct CompanionView: View {
  @EnvironmentObject private var watchConnector: WatchConnector

  var body: some View {
    TabView {
      WizardView()
        .environmentObject(watchConnector)
        .tabItem {
          Image(systemName: "wand.and.rays")
          Text("Wizard")
        }

      GalleryView()
        .tabItem {
          Image(systemName: "photo.on.rectangle.angled")
          Text("Galerie")
        }

      CalendarView()
        .tabItem {
          Image(systemName: "calendar")
          Text("Kalender")
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
