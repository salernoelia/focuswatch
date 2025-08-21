import SwiftUI
import WatchConnectivity

enum WatchViewState {
    case mainMenu
    case app(Int)
}

struct PrototypeApp {
    let title: String;
    let description: String;
    let color: Color;
    let destination: AnyView;
}

struct WatchView: View {
    @EnvironmentObject var watchConnector: WatchConnector
    @State private var currentView: WatchViewState = .mainMenu
    @State private var selectedAppIndex: Int? = nil
    
    private var prototypeApps: [PrototypeApp] {
        var apps: [PrototypeApp] = []
        
        for checklistType in watchConnector.checklistConfiguration.checklistTypes {
            apps.append(PrototypeApp(
                title: checklistType.displayName,
                description: "Interaktive Checkliste",
                color: checklistType.color,
                destination: AnyView(
                    UniversalChecklistView(
                        title: checklistType.displayName,
                        instructionTitle: checklistType.displayName,
                        items: checklistType.items
                    )
                )
            ))
        }
        
        apps.append(contentsOf: [
            PrototypeApp(
                title: "Farbatmung",
                description: "Beruhigende Atemübungen",
                color: .green,
                destination: AnyView(ColorBreathingView())
            ),
            PrototypeApp(
                title: "Fidget Spinner",
                description: "Digitaler Fidget Spinner",
                color: .orange,
                destination: AnyView(FidgetSpinnerView())
            )
        ])
        
        return apps
    }
    
    var body: some View {
        NavigationView {
            Group {
                if let selectedIndex = selectedAppIndex, selectedIndex < prototypeApps.count {
                    prototypeApps[selectedIndex].destination
                        .navigationBarHidden(true)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(Array(prototypeApps.enumerated()), id: \.offset) { index, app in
                                NavigationLink(
                                    destination: app.destination,
                                    tag: index,
                                    selection: $selectedAppIndex
                                ) {
                                    AppCard(app: app)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 8)
                    }
                    .navigationTitle("Apps")
                    .navigationBarTitleDisplayMode(.inline)
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
}

#Preview {
    WatchView()
        .environmentObject(WatchConnector())
}
