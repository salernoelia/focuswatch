import SwiftUI

struct WritingView: View {
  @StateObject private var configs = UserConfigs.shared
  @EnvironmentObject var WritingExerciseManager: WritingExerciseManager
  @State private var configsLoaded = false
  private let appLogger = AppLogger.shared

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
      appLogger.logViewLifecycle(appName: "schreiben", event: "open")
    }
    .onDisappear {
      appLogger.logViewLifecycle(appName: "schreiben", event: "close")
    }
  }
}

#Preview {
  WritingView()
}
