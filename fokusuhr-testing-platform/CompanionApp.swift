//
//  fokusuhr_testing_platformApp.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 26.06.2025.
//

import SwiftUI

@main
struct CompanionApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                WizardView()
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
                        Image(systemName: "book.pages")
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
}
