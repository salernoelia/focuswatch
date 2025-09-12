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
    @State private var testUsers: [TestUser] = []

    var body: some Scene {
        WindowGroup {
            VStack {
                List(testUsers, id: \.id) { user in
                    Text(String(user.id))
                    Text(user.first_name)
                    Text(user.last_name)
                    Text(String(user.age))

                }
                WatchView()
                    .environmentObject(watchConnector)
            }
            .task {
                testUsers = await fetchTestUsers()
            }
        }
    }   
}