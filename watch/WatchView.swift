import SwiftUI
import WatchConnectivity

struct WatchView: View {
    @EnvironmentObject var syncCoordinator: SyncCoordinator
    @StateObject private var appsManager = AppsManager.shared
    @StateObject private var checklistManager = ChecklistViewModel.shared
    @State private var currentView: WatchViewState = .mainMenu
    @State private var navigationPath = NavigationPath()

    private func destinationView(for index: Int) -> some View {
        if index == -1 {
            return AnyView(LevelView())
        } else if index == -2 {
            return AnyView(MilestonesView())
        } else if index == -3 {
            return AnyView(ProgressListView())
        }

        guard index < appsManager.apps.count else {
            return AnyView(Text(String(localized: "App not found")))
        }

        let app = appsManager.apps[index]
        let localizedTachometer = String(localized: "Meter")
        let localizedSchreiben = String(localized: "Writing")
        let localizedFarbatmung = String(localized: "Breathing")
        let localizedPomodoro = String(localized: "Pomodoro")
        let localizedFidget = String(localized: "Fidget")
        let localizedAnneBeta = String(localized: "Anne (Beta)")
        let localizedKalender = String(localized: "Calendar")

        return AnyView(
            Group {
                if app.title == localizedTachometer {
                    SpeedometerView()
                } else if app.title == localizedSchreiben {
                    WritingView()
                } else if app.title == localizedFarbatmung {
                    ColorBreathingView()
                } else if app.title == localizedPomodoro {
                    PomodoroView()
                } else if app.title == localizedFidget {
                    FidgetToyView()
                } else if app.title == localizedAnneBeta {
                    AnneView()
                } else if app.title == localizedKalender {
                    CalendarView()
                } else {
                    if let checklist = checklistForApp(app) {
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
        )
    }

    private func checklistForApp(_ app: AppInfo) -> Checklist? {
        let checklistIndex = app.index - appsManager.builtInAppCount
        guard
            checklistIndex >= 0
                && checklistIndex
                    < checklistManager.checklistData.checklists.count
        else {
            return nil
        }
        return checklistManager.checklistData.checklists[checklistIndex]
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            HomeView()
                .navigationDestination(for: Int.self) { index in
                    destinationView(for: index)
                        .navigationBarTitleDisplayMode(.inline)
                }
        }
        .onAppear {
            checklistManager.loadChecklistData()
        }
        .onReceive(syncCoordinator.$currentView) { newView in
            currentView = newView
            switch newView {
            case .mainMenu:
                if !navigationPath.isEmpty {
                    navigationPath.removeLast(navigationPath.count)
                }
            case .app(let index):
                navigationPath.append(index)
            }
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
                        HomeTile(
                            label: String(localized: "Checklists"), symbol: "checklist",
                            color: .blue, minHeight: minHeight
                        ) {
                            ChecklistsListView()
                        }
                        HomeTile(
                            label: String(localized: "Calendar"), symbol: "calendar",
                            color: .red, minHeight: minHeight
                        ) {
                            CalendarView()
                        }
                        HomeTile(
                            label: String(localized: "Level"), symbol: "chart.bar.fill",
                            color: .purple, minHeight: minHeight
                        ) {
                            DashboardView()
                        }
                        ForEach(appsManager.apps.filter { $0.index < appsManager.builtInAppCount })
                        { app in
                            AppHomeTile(app: app, minHeight: minHeight)
                        }
                    }
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Text(String(localized: "Settings"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
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

private struct HomeTile<Destination: View>: View {
    let label: String
    let symbol: String
    let color: Color
    let minHeight: CGFloat
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .padding(.vertical, 6)
            .background(color.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

private struct AppHomeTile: View {
    let app: AppInfo
    let minHeight: CGFloat

    var body: some View {
        NavigationLink(value: app.index) {
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
