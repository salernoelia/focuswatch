import SwiftUI
import WatchConnectivity

struct WizardView: View {
    @EnvironmentObject private var watchConnector: WatchConnector
    @StateObject private var checklistManager: ChecklistManager
    @State private var showingEditor = false
    @State private var isReconnecting = false
    @State private var isSyncing = false
    
    init() {
        let tempConnector = WatchConnector()
        self._checklistManager = StateObject(wrappedValue: ChecklistManager(watchConnector: tempConnector))
    }
    
    private var prototypeApps: [(String, String, Color)] {
        var apps = checklistManager.data.checklists.map { checklist in
            (checklist.name, "Interaktive Checkliste", Color.blue)
        }
        
        apps.append(contentsOf: [
            ("Farbatmung", "Beruhigende Atemübungen", Color.green),
            ("Fidget Spinner", "Digitaler Fidget Spinner", Color.orange),
            ("Anne (Beta)", "Virtueller Assistent", Color.blue)
        ])
        
        return apps
    }
    
    var body: some View {
        NavigationView {
            List {

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
                     Button("Put Watch into Menu State") {
                        watchConnector.returnToMainMenu()
                    }
                    .disabled(!watchConnector.isConnected)
                     Button("Edit Checklists") {
                        showingEditor = true
                    }
                    
                }
                
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
                    

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Debug Info:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Activation: \(WCSession.default.activationState.rawValue)")
                            .font(.caption2)
                        Text("Reachable: \(WCSession.default.isReachable)")
                            .font(.caption2)
                        Text("Paired: \(WCSession.default.isPaired)")
                            .font(.caption2)
                        Text("App Installed: \(WCSession.default.isWatchAppInstalled)")
                            .font(.caption2)
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
                        
                        Button(action: resetConnection) {
                            HStack {
                                Image(systemName: "wifi.slash")
                                Text("Reset Connection")
                            }
                        }
                        .disabled(isReconnecting)
                        .foregroundColor(.orange)
                    }
                }
                
                 Button(action: forceSyncToWatch) {
                HStack {
                    if isSyncing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                                 .foregroundColor(.red)
                    }
                    Text(isSyncing ? "Force Syncing..." : "Force Sync All Data")
                        .foregroundColor(.red)
                }
            }
            .disabled(!watchConnector.isConnected || isSyncing)
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Wizard of Oz")
            .sheet(isPresented: $showingEditor) {
                ChecklistEditorView(checklistManager: checklistManager)
            }
            .onAppear {
                // Sync the watchConnector with checklistManager when view appears
                checklistManager.watchConnector = watchConnector
                watchConnector.checklistData = ChecklistManager.loadSharedData()
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
    
    private func resetConnection() {
        isReconnecting = true
        
        // Use the new reset method
        watchConnector.resetWatchConnectivity()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            isReconnecting = false
        }
    }
    
    private func forceSyncToWatch() {
        isSyncing = true
        
        watchConnector.updateChecklistData(checklistManager.data)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isSyncing = false
        }
    }
}

#Preview {
    WizardView()
}
