import SwiftUI
import WatchConnectivity

struct WizardView: View {
  @EnvironmentObject private var watchConnector: WatchConnector
  @StateObject private var checklistManager = ChecklistViewModel(
    watchConnector: WatchConnector.shared
  )
  @StateObject private var testUsersManager = TestUsersManager.shared
  @StateObject private var supervisorManager = SupervisorManager.shared
  @StateObject private var authManager = AuthManager.shared
  @StateObject private var appsManager = AppsManager.shared
  @State private var isReconnecting = false
  @State private var isSyncing = false

  private var connectionStatus: ConnectionStatus {
    if !WCSession.isSupported() {
      return .notSupported
    }
    if !watchConnector.isConnected {
      return .disconnected
    }
    if !WCSession.default.isPaired {
      return .notPaired
    }
    if !WCSession.default.isWatchAppInstalled {
      return .appNotInstalled
    }
    if !WCSession.default.isReachable {
      return .notReachable
    }
    return .connected
  }

  private enum ConnectionStatus {
    case notSupported
    case disconnected
    case notPaired
    case appNotInstalled
    case notReachable
    case connected

    var color: Color {
      switch self {
      case .connected: return .green
      case .notReachable: return .orange
      default: return .red
      }
    }

    var statusText: String {
      switch self {
      case .notSupported: return "Not Supported"
      case .disconnected: return "Disconnected"
      case .notPaired: return "Not Paired"
      case .appNotInstalled: return "App Not Installed"
      case .notReachable: return "Connected"
      case .connected: return "Connected"
      }
    }

    var infoMessage: String? {
      switch self {
      case .notSupported:
        return "Apple Watch is not supported on this device"
      case .disconnected:
        return "Unable to connect to Apple Watch"
      case .notPaired:
        return "Please pair an Apple Watch with this iPhone"
      case .appNotInstalled:
        return
          "Please install the Watch App from the Watch app on your iPhone"
      case .notReachable:
        return "Open the Watch App to control it directly"
      case .connected:
        return nil
      }
    }

    var needsReconnect: Bool {
      switch self {
      case .notSupported, .notPaired, .appNotInstalled:
        return false
      default:
        return self != .connected
      }
    }
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
                .fill(connectionStatus.color)
                .frame(
                  width: AppConstants.UI.statusIndicatorSize,
                  height: AppConstants.UI.statusIndicatorSize
                )
              Text(connectionStatus.statusText)
                .foregroundColor(connectionStatus.color)
            }
          }

          if let infoMessage = connectionStatus.infoMessage {
            HStack(alignment: .top, spacing: 8) {
              Image(systemName: "info.circle")
                .foregroundColor(connectionStatus.color)
              Text(infoMessage)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 4)
          }

          if connectionStatus.needsReconnect {
            Button(action: reconnectToWatch) {
              HStack {
                if isReconnecting {
                  ProgressView()
                    .scaleEffect(
                      AppConstants.UI.progressScaleFactor
                    )
                } else {
                  Image(systemName: "arrow.clockwise")
                }
                Text(
                  isReconnecting
                    ? "Reconnecting..." : "Try to Reconnect"
                )
              }
            }
            .disabled(isReconnecting)
          }
        }

        Section("Focus Tools") {
          ForEach(appsManager.apps.filter { $0.index < appsManager.builtInAppCount }, id: \.id) {
            app in
            Button {
              watchConnector.switchToApp(index: app.index)
            } label: {
              HStack(spacing: 12) {
                Circle()
                  .fill(app.color)
                  .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 2) {
                  Text(app.title)
                    .foregroundColor(.primary)
                  Text(app.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
              }
            }
            .disabled(connectionStatus != .connected)
          }
        }

        if appsManager.apps.count > appsManager.builtInAppCount {
          Section("Checklists") {
            ForEach(appsManager.apps.filter { $0.index >= appsManager.builtInAppCount }, id: \.id) {
              app in
              Button {
                watchConnector.switchToApp(index: app.index)
              } label: {
                HStack(spacing: 12) {
                  Circle()
                    .fill(app.color)
                    .frame(width: 10, height: 10)

                  VStack(alignment: .leading, spacing: 2) {
                    Text(app.title)
                      .foregroundColor(.primary)
                    Text(app.description)
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }
                }
              }
              .disabled(connectionStatus != .connected)
            }
          }
        }

        Section("Progress") {
          Button {
            watchConnector.switchToApp(index: -1)
          } label: {
            HStack(spacing: 12) {
              Circle()
                .fill(Color.blue)
                .frame(width: 10, height: 10)

              VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "Level"))
                  .foregroundColor(.primary)
                Text(String(localized: "See your focus points"))
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
            }
          }
          .disabled(connectionStatus != .connected)

          Button {
            watchConnector.switchToApp(index: -2)
          } label: {
            HStack(spacing: 12) {
              Circle()
                .fill(Color.teal)
                .frame(width: 10, height: 10)

              VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "Milestones"))
                  .foregroundColor(.primary)
                Text(String(localized: "Track your achievements"))
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
            }
          }
          .disabled(connectionStatus != .connected)
        }

        Section("Navigation") {
          Button("Return to Dashboard") {
            watchConnector.returnToMainMenu()
          }
          .disabled(connectionStatus != .connected)
        }

        Section("Advanced") {
          Button(action: forceSyncToWatch) {
            HStack {
              if isSyncing {
                ProgressView()
                  .scaleEffect(AppConstants.UI.progressScaleFactor)
              }
              Text(isSyncing ? "Force Syncing..." : "Force Sync All Data")
                .foregroundColor(isSyncing ? .secondary : .red)
            }
          }
          .disabled(!watchConnector.isConnected || isSyncing)
        }
      }
      .listStyle(.insetGrouped)
      .refreshable {
        if authManager.isLoggedIn {
          await testUsersManager.fetchTestUsers()
          await supervisorManager.fetchCurrentSupervisor()
        }
        reconnectToWatch()
      }
      .navigationTitle("Wizard")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          HStack {
            Text("Watch ID:")
            Text(String(WatchConfig.shared.uuid.prefix(8)))
              .font(.system(.body, design: .monospaced))
              .foregroundColor(.secondary)
          }
        }
      }

      .onAppear {
        checklistManager.watchConnector = watchConnector
        watchConnector.checklistData =
          ChecklistViewModel.loadSharedData()
        tryInitialWatchConnect()
      }

    }
  }

  private func reconnectToWatch() {
    isReconnecting = true
    watchConnector.forceReconnect()

    DispatchQueue.main.asyncAfter(
      deadline: .now() + AppConstants.Timing.longDelay
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
