import SwiftUI

struct ChecklistSettingsView: View {
  @State private var appConfigurations = ConfigSyncService.shared.loadFromUserDefaults()

  var body: some View {
    Form {
      Section {
        Picker(NSLocalizedString("Swipe Mapping", comment: ""), selection: $appConfigurations.checklistSwipeMapping) {
          Text(NSLocalizedString("Collect: Right", comment: ""))
            .tag(ChecklistSwipeDirectionMapping.collectRightDelayLeft)
          Text(NSLocalizedString("Collect: Left", comment: ""))
            .tag(ChecklistSwipeDirectionMapping.collectLeftDelayRight)
        }
        .pickerStyle(.menu)
        .onChange(of: appConfigurations.checklistSwipeMapping, initial: false) { _, _ in
          ConfigSyncService.shared.saveToUserDefaults(appConfigurations)
          ConfigSyncService.shared.sync(appConfigurations)
        }
      }
    }
    .navigationTitle(NSLocalizedString("Checklist Settings", comment: ""))
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  NavigationStack {
    ChecklistSettingsView()
  }
}
