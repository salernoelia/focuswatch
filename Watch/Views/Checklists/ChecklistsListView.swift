import SwiftUI

struct ChecklistsListView: View {
  @StateObject private var appsManager = AppsManager.shared
  @StateObject private var checklistManager = ChecklistViewModel.shared

  private var checklistApps: [AppInfo] {
    appsManager.apps.filter { $0.index >= appsManager.builtInAppCount }
  }

  var body: some View {
    ScrollView {
      LazyVStack(spacing: 12) {
        if checklistApps.isEmpty {
          Text(String(localized: "No checklists available"))
            .foregroundStyle(.secondary)
            .font(.caption)
            .padding(.top, 20)
        } else {
          ForEach(Array(checklistApps.enumerated()), id: \.offset) { index, app in
            NavigationLink(value: app.index) {
              AppCardView(app: app)
            }
            .buttonStyle(PlainButtonStyle())
          }
        }
      }
      .padding(.horizontal, 8)
      .padding(.top, 8)
    }
    .navigationTitle(String(localized: "Checklists"))
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  NavigationStack {
    ChecklistsListView()
  }
}
