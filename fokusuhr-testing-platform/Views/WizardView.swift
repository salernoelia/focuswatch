import SwiftUI
import WatchConnectivity

struct WizardView: View {
  @EnvironmentObject private var watchConnector: WatchConnector
  @StateObject private var checklistManager: ChecklistManager
  @StateObject private var testUsersManager = TestUsersManager.shared
  @StateObject private var supervisorManager = SupervisorManager.shared
  @StateObject private var authManager = AuthManager.shared
  @StateObject private var appsManager = AppsManager.shared
  @State private var showingEditor = false
  @State private var isReconnecting = false
  @State private var isSyncing = false

  init() {
    let tempConnector = WatchConnector()
    self._checklistManager = StateObject(
      wrappedValue: ChecklistManager(watchConnector: tempConnector))

  }

  var body: some View {
    NavigationView {
      List {

        Section("Connection") {
          HStack {
            Text("Watch Status")
            Spacer()
            HStack(spacing: AppConstants.UI.statusIndicatorSize) {
              Circle()
                .fill(watchConnector.isConnected ? .green : .red)
                .frame(
                  width: AppConstants.UI.statusIndicatorSize,
                  height: AppConstants.UI.statusIndicatorSize
                )
              Text(watchConnector.isConnected ? "Connected" : "Disconnected")
                .foregroundColor(watchConnector.isConnected ? .green : .red)
            }
          }

          if !watchConnector.isConnected {
            Button(action: reconnectToWatch) {
              HStack {
                if isReconnecting {
                  ProgressView()
                    .scaleEffect(AppConstants.UI.progressScaleFactor)
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
                  .frame(
                    width: AppConstants.UI.cornerRadius,
                    height: AppConstants.UI.cornerRadius
                  )
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

        Button(action: forceSyncToWatch) {
          HStack {
            if isSyncing {
              ProgressView()
                .scaleEffect(
                  AppConstants.UI.progressScaleFactor)
            } else {
              Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundColor(.red)
            }
            Text(
              isSyncing
                ? "Force Syncing..." : "Force Sync All Data"
            )
            .foregroundColor(.red)
          }
        }
        .disabled(!watchConnector.isConnected || isSyncing)
      }
      .listStyle(.insetGrouped)
      .refreshable {
        await testUsersManager.fetchTestUsers()
        await supervisorManager.fetchCurrentSupervisor()
        await appsManager.fetchApps()
      }
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
        tryInitialWatchConnect()
      }

    }
  }

  private func reconnectToWatch() {
    isReconnecting = true

    DispatchQueue.main.asyncAfter(
      deadline: .now() + AppConstants.Timing.shortDelay
    ) {
      watchConnector.forceReconnect()

      DispatchQueue.main.asyncAfter(
        deadline: .now() + AppConstants.Timing.longDelay
      ) {
        isReconnecting = false
      }
    }
  }

  private func resetConnection() {
    isReconnecting = true

    watchConnector.resetWatchConnectivity()

    DispatchQueue.main.asyncAfter(
      deadline: .now() + AppConstants.Timing.reconnectionDelay
    ) {
      isReconnecting = false
    }
  }

  private func forceSyncToWatch() {
    isSyncing = true

    watchConnector.updateChecklistData(checklistManager.data)

    DispatchQueue.main.asyncAfter(
      deadline: .now() + AppConstants.Timing.longDelay
    ) {
      isSyncing = false
    }
  }

  private func tryInitialWatchConnect() {
    guard !watchConnector.isConnected else { return }
    reconnectToWatch()
  }

}

#Preview {
  WizardView()
}
