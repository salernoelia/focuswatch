import Foundation
import WatchConnectivity

class WatchConnector: NSObject, ObservableObject, WCSessionDelegate {
    @Published var isConnected = false
    @Published var checklistData = ChecklistData.default
    @Published var lastError: AppError?

    override init() {
        super.init()
        loadChecklistData()
        setupWatchConnectivity()
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        DispatchQueue.main.async {
            self.isConnected =
                activationState == .activated && session.isReachable

            if let error = error {
                let appError = AppError.watchMessageFailed(underlying: error)
                #if DEBUG
                    ErrorLogger.log(appError)
                #endif
                self.lastError = appError
            } else {
                #if DEBUG
                    print(
                        "WCSession activated with state: \(activationState.rawValue)"
                    )
                #endif
            }

            if self.isConnected {
                self.syncChecklistToWatch()
                self.syncAuthToWatch()
                self.syncTelemetryToWatch()
            }
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isConnected = false
            self.lastError = .watchSessionInactive

            #if DEBUG
                print("WCSession became inactive")
            #endif
        }
    }

    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isConnected = false

            #if DEBUG
                print("WCSession deactivated")
            #endif
        }

        session.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isConnected = session.isReachable

            #if DEBUG
                print("WCSession reachability changed: \(session.isReachable)")
            #endif

            if self.isConnected {
                self.syncChecklistToWatch()
                self.syncAuthToWatch()
                self.syncTelemetryToWatch()
            }
        }
    }

}
