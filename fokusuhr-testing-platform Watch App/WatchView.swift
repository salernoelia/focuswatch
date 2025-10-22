import SwiftUI
import WatchConnectivity

enum WatchViewState {
  case mainMenu
  case app(Int)
}

struct PrototypeApp {
  let title: String
  let description: String
  let color: Color
  let destination: AnyView
}

struct WatchView: View {
  @EnvironmentObject var watchConnector: WatchConnector
  @StateObject private var appsManager = AppsManager.shared
  @StateObject private var checklistManager = ChecklistManager.shared
  @State private var currentView: WatchViewState = .mainMenu
  @State private var selectedAppIndex: Int? = nil
  @State private var selectedTab = 0

  private var prototypeApps: [PrototypeApp] {
    appsManager.apps.map { app in
      let destination = destinationView(for: app)
      return PrototypeApp(
        title: app.title,
        description: app.description,
        color: app.color,
        destination: AnyView(destination)
      )
    }
  }

  private func destinationView(for app: AppInfo) -> some View {
    Group {
      switch app.title {
      case "Tachometer":
        SpeedometerView()
      case "Schreiben":
        WritingView()
      case "Farbatmung":
        ColorBreathingView()
      case "Anne (Beta)":
        AnneView()
      case "Calendar":
        CalendarView()
      default:
        if let checklist = checklistForApp(app) {
          UniversalChecklistView(
            title: checklist.name,
            description: checklist.description,
            instructionTitle: checklist.name,
            items: checklist.items,
            checklistId: checklist.id,
            selectedAppIndex: $selectedAppIndex
          )
        } else {
          Text("App not found")
        }
      }
    }
  }

  private func checklistForApp(_ app: AppInfo) -> Checklist? {
    let checklistIndex = app.index - appsManager.builtInAppCount
    guard checklistIndex >= 0 && checklistIndex < checklistManager.checklistData.checklists.count
    else {
      return nil
    }
    return checklistManager.checklistData.checklists[checklistIndex]
  }

  var body: some View {

    NavigationView {
      Group {
        if let selectedIndex = selectedAppIndex,
          selectedIndex < prototypeApps.count
        {
          prototypeApps[selectedIndex].destination
            .navigationBarHidden(false)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
              ToolbarItem(placement: .cancellationAction) {
                Button("Zurück") {
                  selectedAppIndex = nil
                }
              }
            }
        } else {
          mainMenuView
        }
      }
    }
    .tag(1)

    .onAppear {
      selectedTab = 0
      checklistManager.loadChecklistData()
    }
    .onReceive(watchConnector.$currentView) { newView in
      currentView = newView
      switch newView {
      case .mainMenu:
        selectedAppIndex = nil
        selectedTab = 1
      case .app(let index):
        if index < prototypeApps.count {
          selectedAppIndex = index
          selectedTab = 1
        }
      }
    }
  }

  private var mainMenuView: some View {
    ScrollView {
      LazyVStack(spacing: 12) {
        ForEach(Array(prototypeApps.enumerated()), id: \.offset) {
          index,
          app in
          appNavigationLink(for: app, at: index)
        }
      }
      .padding(.horizontal, 8)
      .padding(.top, 8)
    }
    .navigationTitle("Apps")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func appNavigationLink(for app: PrototypeApp, at index: Int)
    -> some View
  {
    NavigationLink(
      destination: app.destination,
      tag: index,
      selection: $selectedAppIndex
    ) {
      AppCardView(
        app: AppInfo(
          title: app.title,
          description: app.description,
          color: app.color
        )
      )
    }
    .buttonStyle(PlainButtonStyle())
  }
}

#Preview {
  WatchView()
    .environmentObject(WatchConnector())
}
