import SwiftUI
import WatchConnectivity

enum WatchViewState {
  case mainMenu
  case app(Int)
}

struct WatchView: View {
  @EnvironmentObject var watchConnector: WatchConnector
  @StateObject private var appsManager = AppsManager.shared
  @StateObject private var checklistManager = ChecklistViewModel.shared
  @State private var currentView: WatchViewState = .mainMenu
  @State private var navigationPath = NavigationPath()

  private func destinationView(for index: Int) -> some View {
    guard index < appsManager.apps.count else {
      return AnyView(Text(String(localized: "App not found")))
    }

    let app = appsManager.apps[index]
    let localizedTachometer = String(localized: "Fokus Meter")
    let localizedSchreiben = String(localized: "Writing")
    let localizedFarbatmung = String(localized: "Color Breathing")
    let localizedPomodoro = String(localized: "Pomodoro")
    let localizedFidget = String(localized: "Fidget Toy")
    let localizedAnneBeta = String(localized: "Anne (Beta)")
    let localizedKalender = String(localized: "Calendar")
    let localizedLevel = String(localized: "Level")

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
        } else if app.title == localizedLevel {
          LevelView()
        } else {
          if let checklist = checklistForApp(app) {
            UniversalChecklistView(
              title: checklist.name,
              description: checklist.description,
              instructionTitle: checklist.name,
              items: checklist.items,
              checklistId: checklist.id,
              xpReward: checklist.xpReward
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
      TabView {
        DashboardView()
        CalendarView()
        FocusToolsListView()
        ChecklistsListView()
      }
      .tabViewStyle(.page)
      .navigationDestination(for: Int.self) { index in
        destinationView(for: index)
          .navigationBarTitleDisplayMode(.inline)
      }
    }
    .onAppear {
      checklistManager.loadChecklistData()
    }
    .onReceive(watchConnector.$currentView) { newView in
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

#Preview {
  WatchView()
    .environmentObject(WatchConnector.shared)
}
