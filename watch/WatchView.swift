import SwiftUI
import WatchConnectivity

struct WatchView: View {
    @EnvironmentObject var syncCoordinator: SyncCoordinator
    @StateObject private var appsManager = AppsManager.shared
    @StateObject private var checklistManager = ChecklistViewModel.shared
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            HomeView()
                .navigationDestination(for: String.self) { appID in
                    destinationView(for: appID)
                        .navigationBarTitleDisplayMode(.inline)
                }
        }
        .onAppear {
            checklistManager.loadChecklistData()
        }
        .onReceive(syncCoordinator.$currentView) { newView in
            switch newView {
            case .mainMenu:
                if !navigationPath.isEmpty {
                    navigationPath.removeLast(navigationPath.count)
                }
            case .app(let appID):
                navigationPath.append(appID)
            }
        }
    }

    @ViewBuilder
    private func destinationView(for id: String) -> some View {
        if let appID = WatchAppID(rawValue: id) {
            builtInDestination(for: appID)
        } else {
            checklistDestination(for: id)
        }
    }

    @ViewBuilder
    private func builtInDestination(for appID: WatchAppID) -> some View {
        switch appID {
        case .checklists:
            ChecklistsListView()
        case .calendar:
            CalendarView()
        case .level:
            DashboardView()
        case .meter:
            SpeedometerView()
        case .writing:
            WritingView()
        case .pomodoro:
            PomodoroView()
        case .fidget:
            FidgetToyView()
        case .breathing:
            ColorBreathingView()
        case .settings:
            SettingsView()
        }
    }

    @ViewBuilder
    private func checklistDestination(for id: String) -> some View {
        if let checklist = checklistManager.checklistData.checklists.first(where: { $0.id.uuidString == id }) {
            UniversalChecklistView(
                title: checklist.name,
                description: checklist.description,
                instructionTitle: checklist.name,
                items: checklist.items,
                checklistId: checklist.id,
                xpReward: checklist.xpReward,
                resetConfiguration: checklist.resetConfiguration
            )
        } else {
            Text(String(localized: "App not found"))
        }
    }
}

private struct HomeView: View {
    @StateObject private var appsManager = AppsManager.shared

    var body: some View {
        GeometryReader { geo in
            let tileSize = (geo.size.width - 6) / 2
            let minHeight = tileSize * 0.75
            ScrollView {
                VStack(spacing: 4) {
                    LazyVGrid(
                        columns: [
                            GridItem(.fixed(tileSize), spacing: 4),
                            GridItem(.fixed(tileSize), spacing: 4),
                        ],
                        spacing: 4
                    ) {
                        ForEach(appsManager.homeTiles) { tile in
                            HomeTile(app: tile, minHeight: minHeight)
                        }
                    }
                    NavigationLink(value: WatchAppID.settings.rawValue) {
                        Text(String(localized: "Settings"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white.opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 2)
                .padding(.top, 2)
                .padding(.bottom, 4)
            }
        }
    }
}

private struct HomeTile: View {
    let app: AppInfo
    let minHeight: CGFloat

    var body: some View {
        NavigationLink(value: app.id) {
            VStack(spacing: 8) {
                if !app.symbol.isEmpty {
                    Image(systemName: app.symbol)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(app.color)
                } else if !app.emoji.isEmpty {
                    Text(app.emoji)
                        .font(.system(size: 24))
                }
                Text(app.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .padding(.vertical, 6)
            .background(app.color.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    WatchView()
        .environmentObject(SyncCoordinator.shared)
}
