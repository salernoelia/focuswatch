import SwiftUI
import WatchConnectivity

struct WatchView: View {
    @StateObject private var watchConnector = WatchConnector()
    @State private var currentView: WatchViewState = .mainMenu
    
    private let prototypeApps: [PrototypeApp] = [
        PrototypeApp(
            title: "Bastelliste",
            description: "Interaktives Checkliste",
            color: .blue,
            destination: AnyView(BastelChecklistView())
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
        Group {
            switch currentView {
            case .mainMenu:
                NavigationStack {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(prototypeApps, id: \.id) { app in
                                NavigationLink(destination: app.destination) {
                                    AppCard(app: app)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                    .navigationTitle("Apps")
                    .navigationBarTitleDisplayMode(.inline)
                }
            case .app(let index):
                if index < prototypeApps.count {
                    prototypeApps[index].destination
                }
            }
        }
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
