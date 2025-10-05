import Foundation
import WatchConnectivity

class WatchConnector: NSObject, ObservableObject, WCSessionDelegate {
    @Published var currentView: WatchViewState = .mainMenu

    private var authManager = AuthManager.shared
    private var checklistManager = ChecklistManager.shared
    private var galleryManager = GalleryManager.shared

    override init() {
        super.init()
        checklistManager.loadChecklistData()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        DispatchQueue.main.async {
            if let error = error {
                print(
                    "Watch WCSession activation error: \(error.localizedDescription)"
                )
            } else {
                print(
                    "Watch WCSession activated with state: \(activationState.rawValue)"
                )
                print("Watch session reachable: \(session.isReachable)")

            }
        }
    }

    func session(
        _ session: WCSession, didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        DispatchQueue.main.async { [self] in
            if let action = message["action"] as? String {
                switch action {
                case "switchToApp":
                    self.currentView = .mainMenu
                    if let appIndex = message["appIndex"] as? Int {
                        self.currentView = .app(appIndex)
                    }
                    replyHandler(["status": "success"])
                case "returnToMainMenu", "wakeUp":
                    self.currentView = .mainMenu
                    replyHandler(["status": "success"])
                case "updateChecklist":
                    if let dataString = message["data"] as? String,
                        let data = Data(base64Encoded: dataString)
                    {
                        let forceOverwrite =
                            message["forceOverwrite"] as? Bool ?? false
                        checklistManager.updateChecklistData(
                            from: data, forceOverwrite: forceOverwrite)
                    }
                    if let imageData = message["imageData"] as? [String: String]
                    {
                        galleryManager.saveGalleryImages(imageData)
                    }
                    replyHandler(["status": "success"])
                case "updateAuth":
                    if let isLoggedIn = message["isLoggedIn"] as? Bool {
                        if isLoggedIn,
                            let accessToken = message["accessToken"] as? String,
                            let refreshToken = message["refreshToken"]
                                as? String
                        {
                            self.authManager.updateAuthState(
                                accessToken: accessToken,
                                refreshToken: refreshToken)
                        } else {
                            self.authManager.clearAuthState()
                        }
                    }
                    replyHandler(["status": "success"])
                case "updateTelemetry":
                    if let hasConsent = message["hasConsent"] as? Bool {
                        TelemetryManager.shared.hasConsent = hasConsent
                    }
                    replyHandler(["status": "success"])
                default:
                    replyHandler(["status": "unknown_action"])
                }
            } else {
                replyHandler(["status": "no_action"])
            }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any])
    {
        DispatchQueue.main.async { [self] in
            if let action = message["action"] as? String {
                switch action {
                case "switchToApp":
                    self.currentView = .mainMenu
                    if let appIndex = message["appIndex"] as? Int {
                        self.currentView = .app(appIndex)
                    }
                case "returnToMainMenu", "wakeUp":
                    self.currentView = .mainMenu
                case "updateChecklist":
                    if let dataString = message["data"] as? String,
                        let data = Data(base64Encoded: dataString)
                    {
                        let forceOverwrite =
                            message["forceOverwrite"] as? Bool ?? false
                        checklistManager.updateChecklistData(
                            from: data, forceOverwrite: forceOverwrite)
                    }
                    if let imageData = message["imageData"] as? [String: String]
                    {
                        galleryManager.saveGalleryImages(imageData)
                    }
                case "updateAuth":
                    if let isLoggedIn = message["isLoggedIn"] as? Bool {
                        if isLoggedIn,
                            let accessToken = message["accessToken"] as? String,
                            let refreshToken = message["refreshToken"]
                                as? String
                        {
                            self.authManager.updateAuthState(
                                accessToken: accessToken,
                                refreshToken: refreshToken)
                        } else {
                            self.authManager.clearAuthState()
                        }
                    }
                case "updateTelemetry":
                    if let hasConsent = message["hasConsent"] as? Bool {
                        TelemetryManager.shared.hasConsent = hasConsent
                    }
                default:
                    break
                }
            }
        }
    }

    func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        DispatchQueue.main.async {
            if let action = applicationContext["action"] as? String {
                switch action {
                case "wakeUp":
                    self.currentView = .mainMenu
                case "updateTelemetry":
                    if let hasConsent = applicationContext["hasConsent"]
                        as? Bool
                    {
                        TelemetryManager.shared.hasConsent = hasConsent
                        print(
                            "Telemetry consent updated via background transfer: \(hasConsent)"
                        )
                    }
                default:
                    break
                }
            }
        }
    }

    func session(
        _ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]
    ) {
        DispatchQueue.main.async {
            if let action = userInfo["action"] as? String {
                switch action {
                case "updateTelemetry":
                    if let hasConsent = userInfo["hasConsent"] as? Bool {
                        TelemetryManager.shared.hasConsent = hasConsent
                        print(
                            "Telemetry consent updated via background transfer: \(hasConsent)"
                        )
                    }
                default:
                    break
                }
            }
        }
    }

   
}
