import SwiftUI
import WatchConnectivity

struct WatchView: View {
    @StateObject private var watchConnector = WatchConnector()
    @State private var currentView: WatchViewState = .mainMenu
    
    private let prototypeApps: [PrototypeApp] = [
        PrototypeApp(
            title: "Bastelliste",
            description: "Interaktive Checkliste",
            color: .blue,
            destination: AnyView(BastelChecklistView())
        ),
        PrototypeApp(
            title: "Rezeptcheckliste",
            description: "Interaktives Checkliste",
            color: .yellow,
            destination: AnyView(RezeptChecklistView())
        ),
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
    ]
    
    var body: some View {
        TabView {
            switch currentView {
            case .mainMenu:
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(prototypeApps, id: \.id) { app in
                            NavigationLink(destination: app.destination) {
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

            case .app(let index):
                if index < prototypeApps.count {
                    prototypeApps[index].destination
                        .navigationBarHidden(true)
                }
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .onReceive(watchConnector.$currentView) { newView in
            currentView = newView
        }
    }
}

enum WatchViewState {
    case mainMenu
    case app(Int)
}

#Preview {
    WatchView()
}