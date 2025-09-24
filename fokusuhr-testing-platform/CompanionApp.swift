//
//  fokusuhr_testing_platformApp.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 26.06.2025.
//

import SwiftUI

@main
struct CompanionApp: SwiftUI.App {
    @StateObject private var watchConnector = WatchConnector()
    @StateObject private var authService = AuthService.shared

    var body: some Scene {
        WindowGroup {
            CompanionView()
                .environmentObject(watchConnector)
                .environmentObject(authService)
        }
    }
}


