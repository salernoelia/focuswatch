import SwiftUI

struct WritingView: View {
  @StateObject private var configs = UserConfigs.shared
  @EnvironmentObject var WritingExerciseManager: WritingExerciseManager
  @State private var configsLoaded = false
  private let telemetryManager = TelemetryManager.shared
  private let appLogger = AppLogger.shared
  private let appName = "writing"

  var body: some View {
    TabView {

      WritingColorView()
        .tabItem {
          Label("Starten", systemImage: "play.circle")
        }

      WritingConfigurationsView(
        current_setting: $configs.configs
      )
      .tabItem {
        Label("Configurations", systemImage: "list.dash")
      }

      NavigationView {
        FileUploadView()
      }
      .tabItem {
        Label("Upload Files", systemImage: "arrow.up.circle")
      }
    }
    .onAppear {
      if let data = telemetryManager.prepareTelemetryData(eventType: "app_opened") {
        Task {
          await appLogger.logEvent(appName: appName, watchId: TelemetryManager.watchId(), data: data)
        }
      }
    }
    .onDisappear {
      if let data = telemetryManager.prepareTelemetryData(eventType: "app_closed") {
        Task {
          await appLogger.logEvent(appName: appName, watchId: TelemetryManager.watchId(), data: data)
        }
      }
    }
  }
}

#Preview {
  WritingView()
}
