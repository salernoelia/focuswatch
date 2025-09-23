//
//  CompanionView.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 23.09.2025.
//

import SwiftUI

struct CompanionView: View {
    @StateObject private var watchConnector = WatchConnector()
    
    var body: some View {
        TabView {
            WizardView()
                .environmentObject(watchConnector)
                .tabItem {
                    Image(systemName: "wand.and.rays")
                    Text("Wizard")
                }

            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }

            JournalView()
                .tabItem {
                    Image(systemName: "book")
                    Text("Journal")
                }

            GalleryView()
                .tabItem {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("Gallery")
                }

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
        }
    }
}

#Preview {
    CompanionView()
}
