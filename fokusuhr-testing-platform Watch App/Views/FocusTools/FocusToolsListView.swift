import SwiftUI

struct FocusToolsListView: View {
    @StateObject private var appsManager = AppsManager.shared
    @EnvironmentObject var syncCoordinator: SyncCoordinator

    private var focusTools: [AppInfo] {
        appsManager.apps.filter { $0.index < appsManager.builtInAppCount }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(focusTools.enumerated()), id: \.offset) { index, app in
                    NavigationLink(value: app.index) {
                        AppCardView(app: app)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
        }
        .navigationTitle(String(localized: "Focus Tools"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        FocusToolsListView()
            .environmentObject(SyncCoordinator.shared)
    }
}
