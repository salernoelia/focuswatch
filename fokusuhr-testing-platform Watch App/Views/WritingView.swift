import SwiftUI

struct WritingView: View {
  @StateObject private var configs = UserConfigs.shared
  @EnvironmentObject var exerciseManager: ExerciseManager
  @State private var configsLoaded = false

  var body: some View {
    TabView {

      ColorView()
        .tabItem {
          Label("Starten", systemImage: "play.circle")
        }

      ConfigurationsView(
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

  }
}

#Preview {
  WritingView()
}
