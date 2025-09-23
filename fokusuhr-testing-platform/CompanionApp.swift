//
//  fokusuhr_testing_platformApp.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 26.06.2025.
//

import SwiftUI

@main
struct CompanionApp: App {
    @StateObject private var watchConnector = WatchConnector()
    
    var body: some Scene {
        WindowGroup {
           CompanionView()
        }
    }
}


