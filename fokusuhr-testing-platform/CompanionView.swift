import SwiftUI
import WatchConnectivity

struct CompanionView: View {
    @StateObject private var watchConnector = WatchConnector()
    
    private let prototypeApps = [
        ("Checkliste", "Interaktives task management", Color.blue),
        ("Farbatmung", "Beruhigende Atemübungen", Color.green),
        ("Fidget Spinner", "Digitaler Fidget Spinner", Color.orange)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Watch Remote Control")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Connection: \(watchConnector.isConnected ? "Connected" : "Disconnected")")
                    .foregroundColor(watchConnector.isConnected ? .green : .red)
                
                VStack(spacing: 12) {
                    ForEach(Array(prototypeApps.enumerated()), id: \.offset) { index, app in
                        Button(action: {
                            watchConnector.switchToApp(index: index)
                        }) {
                            HStack {
                                Circle()
                                    .fill(app.2)
                                    .frame(width: 12, height: 12)
                                VStack(alignment: .leading) {
                                    Text(app.0)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(app.1)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                    Button("Return to Main Menu") {
                        watchConnector.returnToMainMenu()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("Companion")
        }
    }
}
