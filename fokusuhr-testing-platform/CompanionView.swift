import SwiftUI
import WatchConnectivity

struct CompanionView: View {
    @StateObject private var watchConnector = WatchConnector()
    @StateObject private var checklistManager: ChecklistManager
    @State private var showingEditor = false
    
    init() {
        let connector = WatchConnector()
        self._watchConnector = StateObject(wrappedValue: connector)
        self._checklistManager = StateObject(wrappedValue: ChecklistManager(watchConnector: connector))
    }
    
    private var prototypeApps: [(String, String, Color)] {
        var apps = checklistManager.configuration.checklistTypes.map { type in
            (type.displayName, "Interaktive Checkliste", type.color)
        }
        
        apps.append(contentsOf: [
            ("Farbatmung", "Beruhigende Atemübungen", Color.green),
            ("Fidget Spinner", "Digitaler Fidget Spinner", Color.orange)
        ])
        
        return apps
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                
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
                    
                    Button("Edit Checklists") {
                        showingEditor = true
                    }
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("Companion")
        }
        .sheet(isPresented: $showingEditor) {
            ChecklistEditorView(checklistManager: checklistManager)
        }
    }
}
