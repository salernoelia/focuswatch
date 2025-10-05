import Foundation
import WatchConnectivity

class WatchConnector: NSObject, ObservableObject {
    @Published var currentView: WatchViewState = .mainMenu
    @Published var checklistData = ChecklistData.default
    
    private let connectivityManager = WatchConnectivityManager()
    
    override init() {
        super.init()
        checklistData = ChecklistStorage.load()
        connectivityManager.delegate = self
    }
    
}

extension WatchConnector: WatchConnectivityDelegate {
    func didReceiveSwitchToApp(_ index: Int) {
        currentView = .app(index)
    }
    
    func didReceiveReturnToMainMenu() {
        currentView = .mainMenu
    }
    
    func didReceiveChecklistUpdate(_ data: ChecklistData, images: [String: String], forceOverwrite: Bool) {
        if forceOverwrite {
            ChecklistStorage.clearGalleryImages()
        }
        
        checklistData = data
        ChecklistStorage.save(data)
        ChecklistStorage.saveGalleryImages(images)
    }
}
