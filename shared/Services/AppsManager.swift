import Combine
import Foundation
import SwiftUI

class AppsManager: ObservableObject {
    @Published var apps: [AppInfo] = []
    @Published var homeTiles: [AppInfo] = []
    @Published var isLoading = false
    @Published var lastError: AppError?

    private(set) var builtInAppCount: Int = 0

    static let shared = AppsManager()

    private static let tileOrderKey = "homeTileOrder"

    private var cancellables = Set<AnyCancellable>()

    private init() {
        loadApps()
        observeChecklistChanges()
    }

    private func observeChecklistChanges() {
        NotificationCenter.default.publisher(for: .checklistDataChanged)
            .sink { [weak self] _ in
                self?.loadApps()
            }
            .store(in: &cancellables)
    }

    func loadApps() {
        isLoading = true
        lastError = nil

        let allApps = buildAppsList()
        apps = allApps
        homeTiles = applySavedOrder(to: allApps.filter { $0.appID != nil })
        isLoading = false
    }

    private func buildAppsList() -> [AppInfo] {
        var appsList: [AppInfo] = []
        var currentIndex = 0

        let builtInDefinitions: [(WatchAppID, String, String, Color, String)] = [
            (.checklists, String(localized: "Checklists"), "checklist", .blue, ""),

            (.meter, String(localized: "Meter"), "gauge.medium", .yellow,
             String(localized: "How do you feel right now?")),
            (.writing, String(localized: "Writing"), "pencil", .orange,
             String(localized: "Focus aid for writing.")),
            (.pomodoro, String(localized: "Pomodoro"), "timer", .red,
             String(localized: "Timer for time management")),
            (.calendar, String(localized: "Calendar"), "calendar", .red, ""),
            (.level, String(localized: "Level"), "trophy.fill", .purple, ""),
            (.fidget, String(localized: "Fidget"), "hand.tap", .gray,
             String(localized: "Interactive vibration toy")),
            (.breathing, String(localized: "Breathing"), "wind", .green,
             String(localized: "Calming breathing exercises")),
        ]

        builtInAppCount = builtInDefinitions.count

        for (appID, title, symbol, color, description) in builtInDefinitions {
            appsList.append(
                AppInfo(
                    appID: appID,
                    title: title,
                    description: description,
                    color: color,
                    legacyIndex: currentIndex,
                    symbol: symbol
                ))
            currentIndex += 1
        }

        let checklistData = loadChecklistData()
        for checklist in checklistData.checklists {
            appsList.append(
                AppInfo(
                    checklistID: checklist.id,
                    title: checklist.name,
                    emoji: checklist.emoji,
                    legacyIndex: currentIndex
                ))
            currentIndex += 1
        }

        return appsList
    }

    private func applySavedOrder(to allApps: [AppInfo]) -> [AppInfo] {
        guard let savedOrder = UserDefaults.standard.stringArray(forKey: Self.tileOrderKey) else {
            return allApps
        }

        let appsByID = Dictionary(uniqueKeysWithValues: allApps.map { ($0.id, $0) })
        var ordered: [AppInfo] = []

        for id in savedOrder {
            if let app = appsByID[id] {
                ordered.append(app)
            }
        }

        for app in allApps where !savedOrder.contains(app.id) {
            ordered.append(app)
        }

        return ordered
    }

    private func persistOrder() {
        let ids = homeTiles.map(\.id)
        UserDefaults.standard.set(ids, forKey: Self.tileOrderKey)
    }


    func moveTile(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex,
              sourceIndex >= 0, sourceIndex < homeTiles.count,
              destinationIndex >= 0, destinationIndex < homeTiles.count
        else { return }

        let tile = homeTiles.remove(at: sourceIndex)
        homeTiles.insert(tile, at: destinationIndex)
        persistOrder()
    }

    func moveTile(id: String, to destinationIndex: Int) {
        guard let sourceIndex = homeTiles.firstIndex(where: { $0.id == id }) else { return }
        moveTile(from: sourceIndex, to: destinationIndex)
    }

    func setTileOrder(_ orderedIDs: [String]) {
        let appsByID = Dictionary(uniqueKeysWithValues: homeTiles.map { ($0.id, $0) })
        var reordered: [AppInfo] = []

        for id in orderedIDs {
            if let app = appsByID[id] {
                reordered.append(app)
            }
        }

        for tile in homeTiles where !orderedIDs.contains(tile.id) {
            reordered.append(tile)
        }

        homeTiles = reordered
        persistOrder()
    }

    func resetTileOrder() {
        UserDefaults.standard.removeObject(forKey: Self.tileOrderKey)
        homeTiles = apps
    }


    func app(for appID: WatchAppID) -> AppInfo? {
        apps.first { $0.appID == appID }
    }

    func app(forLegacyIndex index: Int) -> AppInfo? {
        apps.first { $0.legacyIndex == index }
    }

    func builtInApps() -> [AppInfo] {
        apps.filter { $0.appID != nil && $0.appID != .checklists && $0.appID != .calendar && $0.appID != .level && $0.appID != .settings }
    }

    func checklistApps() -> [AppInfo] {
        apps.filter { $0.appID == nil }
    }

    // MARK: - Data Loading

    private func loadChecklistData() -> ChecklistData {
        guard let data = UserDefaults.standard.data(forKey: AppConstants.StorageKeys.checklistData) else {
            return ChecklistData.default
        }

        do {
            return try JSONDecoder().decode(ChecklistData.self, from: data)
        } catch {
            let appError = AppError.decodingFailed(type: "checklist data", underlying: error)
            #if DEBUG
                ErrorLogger.log(appError)
            #endif
            lastError = appError
            return ChecklistData.default
        }
    }

    func refreshApps() {
        loadApps()
    }
}

extension Notification.Name {
    static let checklistDataChanged = Notification.Name("checklistDataChanged")
}
