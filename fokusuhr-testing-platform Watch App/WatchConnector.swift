import Foundation
import WatchConnectivity

class WatchConnector: NSObject, ObservableObject, WCSessionDelegate {
  @Published var currentView: WatchViewState = .mainMenu

  private var authManager = AuthManager.shared
  private var checklistManager = ChecklistManager.shared
  private var galleryManager = GalleryManager.shared
  private var calendarManager = CalendarManager.shared

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
        let appError = AppError.watchConnectionFailed(underlying: error)
        #if DEBUG
          ErrorLogger.log(appError)
        #endif
      } else {
        #if DEBUG
          ErrorLogger.log("Watch WCSession activated with state: \(activationState.rawValue)")
          ErrorLogger.log("Watch session reachable: \(session.isReachable)")
        #endif
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
            self.checklistManager.updateChecklistData(
              from: data, forceOverwrite: forceOverwrite)
          }
          if let imageData = message["imageData"] as? [String: String] {
            self.galleryManager.saveGalleryImages(imageData)
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
        case "updateCalendar":
          if let dataString = message["data"] as? String,
            let data = Data(base64Encoded: dataString),
            let events = try? JSONDecoder().decode([EventTransfer].self, from: data)
          {
            self.calendarManager.updateEvents(events)
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

  func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
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
          if let imageData = message["imageData"] as? [String: String] {
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
        case "updateCalendar":
          if let dataString = message["data"] as? String,
            let data = Data(base64Encoded: dataString),
            let events = try? JSONDecoder().decode([EventTransfer].self, from: data)
          {
            self.calendarManager.updateEvents(events)
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
    guard !applicationContext.isEmpty else {
      #if DEBUG
        ErrorLogger.log("Received empty application context")
      #endif
      return
    }

    DispatchQueue.main.async {
      if let action = applicationContext["action"] as? String {
        switch action {
        case "wakeUp":
          self.currentView = .mainMenu
        case "updateTelemetry":
          if let hasConsent = applicationContext["hasConsent"] as? Bool {
            TelemetryManager.shared.hasConsent = hasConsent
            #if DEBUG
              ErrorLogger.log("Telemetry consent updated via background transfer: \(hasConsent)")
            #endif
          }
        default:
          #if DEBUG
            ErrorLogger.log("Unknown action in application context: \(action)")
          #endif
        }
      } else {
        #if DEBUG
          ErrorLogger.log("Application context received without action key")
        #endif
      }
    }
  }

  func session(
    _ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]
  ) {
    guard !userInfo.isEmpty else {
      #if DEBUG
        ErrorLogger.log("Received empty user info")
      #endif
      return
    }

    DispatchQueue.main.async {
      if let action = userInfo["action"] as? String {
        switch action {
        case "updateTelemetry":
          if let hasConsent = userInfo["hasConsent"] as? Bool {
            TelemetryManager.shared.hasConsent = hasConsent
            #if DEBUG
              ErrorLogger.log("Telemetry consent updated via background transfer: \(hasConsent)")
            #endif
          }
        default:
          #if DEBUG
            ErrorLogger.log("Unknown action in user info: \(action)")
          #endif
        }
      } else {
        #if DEBUG
          ErrorLogger.log("User info received without action key")
        #endif
      }
    }
  }
}
