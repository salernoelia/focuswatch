import SwiftUI
import WatchConnectivity

enum WatchViewState {
    case mainMenu
    case app(Int)
}

struct PrototypeApp {
    let title: String
    let description: String
    let color: Color
    let destination: AnyView
}

struct WatchView: View {
    @EnvironmentObject var watchConnector: WatchConnector
    @State private var currentView: WatchViewState = .mainMenu
    @State private var selectedAppIndex: Int? = nil

    private var prototypeApps: [PrototypeApp] {
        var apps: [PrototypeApp] = []

        apps.append(contentsOf: [
            PrototypeApp(
                title: "Tachometer",
                description: "Wie fühlst du dich gerade?",
                color: .yellow,
                destination: AnyView(SpeedometerView())
            ),
            PrototypeApp(
                title: "Farbatmung",
                description: "Beruhigende Atemübungen",
                color: .green,
                destination: AnyView(ColorBreathingView())
            ),
            // PrototypeApp(
            //     title: "Fidget Spinner",
            //     description: "Digitaler Fidget Spinner",
            //     color: .orange,
            //     destination: AnyView(FidgetSpinnerView())
            // ),
            PrototypeApp(
                title: "Anne (Beta)",
                description: "Virtueller Assistent",
                color: .red,
                destination: AnyView(AnneView())
            ),

        ])

        for checklist in watchConnector.checklistData.checklists {
            apps.append(
                PrototypeApp(
                    title: checklist.name,
                    description: "Interaktive Checkliste",
                    color: .blue,
                    destination: AnyView(
                        UniversalChecklistView(
                            title: checklist.name,
                            instructionTitle: checklist.name,
                            items: checklist.items,
                            selectedAppIndex: $selectedAppIndex
                        )
                    )
                ))
        }

        return apps
    }

    var body: some View {
        NavigationView {
            Group {
                if let selectedIndex = selectedAppIndex,
                    selectedIndex < prototypeApps.count
                {
                    prototypeApps[selectedIndex].destination
                        .navigationBarHidden(false)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Zurück") {
                                    selectedAppIndex = nil
                                }
                            }
                        }
                } else {
                    mainMenuView
                }
            }
        }
        .onReceive(watchConnector.$currentView) { newView in
            currentView = newView
            switch newView {
            case .mainMenu:
                selectedAppIndex = nil
            case .app(let index):
                if index < prototypeApps.count {
                    selectedAppIndex = index
                }
            }
        }
    }

    private var mainMenuView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(prototypeApps.enumerated()), id: \.offset) {
                    index, app in
                    appNavigationLink(for: app, at: index)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
        }
        .navigationTitle("Apps")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func appNavigationLink(for app: PrototypeApp, at index: Int)
        -> some View
    {
        NavigationLink(
            destination: app.destination,
            tag: index,
            selection: $selectedAppIndex
        ) {
            AppCard(
                app: AppInfo(
                    title: app.title,
                    description: app.description,
                    color: app.color
                ))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    WatchView()
        .environmentObject(WatchConnector())
}
