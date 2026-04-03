import Combine
import Foundation
import SwiftUI

class AppsManager: ObservableObject {
    @Published var apps: [AppInfo] = []
    @Published var isLoading = false
    @Published var lastError: AppError?

    private(set) var builtInAppCount: Int = 0

    static let shared = AppsManager()

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

        apps = buildAppsList()
        isLoading = false
    }

    private func buildAppsList() -> [AppInfo] {
        var appsList: [AppInfo] = []
        var currentIndex = 0

        let builtInApps = [
            (
                String(localized: "Fokus Meter"), String(localized: "How do you feel right now?"),
                Color.yellow
            ),
            (
                String(localized: "Writing"), String(localized: "Focus aid for writing."),
                Color.orange
            ),
            (
                String(localized: "Pomodoro"), String(localized: "Timer for time management"),
                Color.red
            ),
            (
                String(localized: "Fidget Toy"), String(localized: "Interactive vibration toy"),
                Color.gray
            ),
            (
                String(localized: "Color Breathing"),
                String(localized: "Calming breathing exercises"),
                Color.green
            ),
        ]

        builtInAppCount = builtInApps.count

        for (title, description, color) in builtInApps {
            appsList.append(
                AppInfo(
                    title: title,
                    description: description,
                    color: color,
                    index: currentIndex
                ))
            currentIndex += 1
        }

        let checklistData = loadChecklistData()
        for checklist in checklistData.checklists {
            appsList.append(
                AppInfo(
                    title: checklist.name,
                    emoji: checklist.emoji,
                    description: String(localized: "Interaktive Checkliste"),
                    color: .blue,
                    index: currentIndex
                ))
            currentIndex += 1
        }

        return appsList
    }

    private func loadChecklistData() -> ChecklistData {
        guard let data = UserDefaults.standard.data(forKey: "checklistData") else {
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
