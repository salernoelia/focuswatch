//
//  fokusuhr_prototypenApp.swift
//  fokusuhr-prototypen Watch App
//
//  Created by Elia Salerno on 21.06.2025.
//

import SwiftUI

struct PrototypeApp {
    let id = UUID()
    let title: String
    let description: String
    let color: Color
    let destination: AnyView
}


@main
struct WatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchView()
        }
    }
}
