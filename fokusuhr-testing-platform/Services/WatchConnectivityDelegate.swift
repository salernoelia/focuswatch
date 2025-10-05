import Foundation

protocol WatchConnectivityDelegate: AnyObject {
    func didUpdateConnectionState(_ isConnected: Bool)
    func didEncounterError(_ error: AppError)
}
