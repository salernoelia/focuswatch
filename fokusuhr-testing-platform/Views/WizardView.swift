import SwiftUI
import WatchConnectivity

struct WizardView: View {
    @StateObject private var watchConnector = WatchConnector()
    @StateObject private var checklistManager: ChecklistManager
    @State private var showingEditor = false
    @State private var isReconnecting = false
    
    init() {
        let connector = WatchConnector()
        self._watchConnector = StateObject(wrappedValue: connector)
        self._checklistManager = StateObject(wrappedValue: ChecklistManager(watchConnector: connector))
    }
    
    private var prototypeApps: [(String, String, Color)] {
        var apps = checklistManager.data.checklists.map { checklist in
            (checklist.name, "Interaktive Checkliste", Color.blue)
        }
        
        apps.append(contentsOf: [
            ("Farbatmung", "Beruhigende Atemübungen", Color.green),
            ("Fidget Spinner", "Digitaler Fidget Spinner", Color.orange)
        ])
        
        return apps
    }
    
    var body: some View {
        NavigationView {
            List {
                Section("Connection") {
                    HStack {
                        Text("Watch Status")
                        Spacer()
                        HStack(spacing: 8) {
                            Circle()
                                .fill(watchConnector.isConnected ? .green : .red)
                                .frame(width: 8, height: 8)
                            Text(watchConnector.isConnected ? "Connected" : "Disconnected")
                                .foregroundColor(watchConnector.isConnected ? .green : .red)
                        }
                    }
                    
                    if !watchConnector.isConnected {
                        Button(action: reconnectToWatch) {
                            HStack {
                                if isReconnecting {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                                Text(isReconnecting ? "Reconnecting..." : "Try Reconnecting")
                            }
                        }
                        .disabled(isReconnecting)
                    }
                }

                Section("Applications") {
                    ForEach(Array(prototypeApps.enumerated()), id: \.offset) { idx, app in
                        Button {
                            watchConnector.switchToApp(index: idx)
                        } label: {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(app.0)
                                    Text(app.1)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } icon: {
                                Circle()
                                    .fill(app.2)
                                    .frame(width: 12, height: 12)
                            }
                        }
                        .disabled(!watchConnector.isConnected)
                    }
                }

                Section("Controls") {
                    Button("Put Watch into Menu State") {
                        watchConnector.returnToMainMenu()
                    }
                    .disabled(!watchConnector.isConnected)
                    
                    Button("Edit Checklists") {
                        showingEditor = true
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Wizard of Oz")
            .sheet(isPresented: $showingEditor) {
                ChecklistEditorView(checklistManager: checklistManager)
            }
        }
    }
    
    private func reconnectToWatch() {
        isReconnecting = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            watchConnector.forceReconnect()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                isReconnecting = false
            }
        }
    }
}

#Preview {
    WizardView()
}
