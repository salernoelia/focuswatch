import SwiftUI
import WatchConnectivity

struct WizardView: View {
    @EnvironmentObject private var watchConnector: WatchConnector
    @StateObject private var checklistManager: ChecklistManager
    @StateObject private var testUsersManager = TestUsersManager.shared
    @StateObject private var appsManager = AppsManager.shared
    @State private var showingEditor = false
    @State private var isReconnecting = false
    @State private var isSyncing = false
    
    init() {
        let tempConnector = WatchConnector()
        self._checklistManager = StateObject(wrappedValue: ChecklistManager(watchConnector: tempConnector))
    }
    
    var body: some View {
        NavigationView {
            List {
                Section("Current Test User") {
                    if let selectedUser = testUsersManager.selectedUser {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(selectedUser.fullName)
                                    .font(.headline)
                                    .fontWeight(.medium)
                                Text("Age: \(selectedUser.age)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                if let supervisor = testUsersManager.supervisors.first(where: { $0.uid == selectedUser.supervisor_uid }) {
                                    Text("Supervisor: \(supervisor.fullName)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            NavigationLink("", destination: UserSelectionView())
                                .font(.subheadline)
                        }
                        .padding(.vertical, 4)
                    } else {
                        HStack {
                            Text("No user selected")
                                .font(.subheadline)
                                .foregroundColor(.red)
                            Spacer()
                            NavigationLink("Select User", destination: UserSelectionView())
                                .font(.subheadline)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Applications") {
                    ForEach(appsManager.apps, id: \.id) { app in
                        Button {
                            watchConnector.switchToApp(index: app.index)
                        } label: {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(app.title)
                                    Text(app.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } icon: {
                                Circle()
                                    .fill(app.color)
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
                    .onDisappear {
                        appsManager.refreshApps()
                    }
            }
            .onAppear {
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
