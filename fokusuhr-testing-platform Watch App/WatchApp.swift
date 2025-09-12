//
//  fokusuhr_prototypenApp.swift
//  fokusuhr-prototypen Watch App
//
//  Created by Elia Salerno on 21.06.2025.
//

import SwiftUI



@main
struct WatchApp: App {
    @StateObject private var watchConnector = WatchConnector()
    
    var body: some Scene {
        WindowGroup {
            WatchView()
                .environmentObject(watchConnector)
        }
    }   
}
