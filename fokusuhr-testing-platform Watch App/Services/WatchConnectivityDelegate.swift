import Foundation
import WatchConnectivity

protocol WatchConnectivityDelegate: AnyObject {
    func didReceiveSwitchToApp(_ index: Int)
    func didReceiveReturnToMainMenu()
    func didReceiveChecklistUpdate(_ data: ChecklistData, images: [String: String], forceOverwrite: Bool)
}
