
import Foundation
import Combine
import SwiftUI
import SwiftData

@MainActor
class AppsManager: ObservableObject {
    @Published var apps: [AppInfo] = []
    @Published var isLoading = false
    
    private let modelContext: ModelContext
    
    static let shared = AppsManager()
    
    private init() {
        self.modelContext = ModelContainerProvider.shared.container.mainContext
        Task {
            await fetchApps()
        }
    }
    
    func fetchApps() async {
        await MainActor.run { isLoading = true }
        
        await MainActor.run {
            apps = buildAppsList()
            isLoading = false
        }
    }
    
    private func buildAppsList() -> [AppInfo] {
        var appsList: [AppInfo] = []
        var currentIndex = 0
        
        let builtInApps = [
            ("Tachometer", "Gefühlsanzeige", Color.yellow),
            ("Farbatmung", "Beruhigende Atemübungen", Color.green),
            ("Anne (Beta)", "Virtueller Assistent", Color.red)
        ]
        
        for (title, description, color) in builtInApps {
            appsList.append(AppInfo(
                title: title,
                description: description,
                color: color,
                index: currentIndex
            ))
            currentIndex += 1
        }

        let descriptor = FetchDescriptor<ChecklistModel>(
            sortBy: [SortDescriptor(\.name)]
        )
        
        do {
            let checklists = try modelContext.fetch(descriptor)
            for checklist in checklists {
                appsList.append(AppInfo(
                    title: checklist.name,
                    description: "Interaktive Checkliste",
                    color: .blue,
                    index: currentIndex
                ))
                currentIndex += 1
            }
        } catch {
            #if DEBUG
            ErrorLogger.log(.databaseQueryFailed(operation: "fetch checklists for apps", underlying: error))
            #endif
        }
        
        return appsList
    }
    
    func refreshApps() {
        Task {
            await fetchApps()
        }
    }
    
}




