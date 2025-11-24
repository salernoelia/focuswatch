import Foundation
import WatchConnectivity

class WatchConnector: NSObject, ObservableObject, WCSessionDelegate {
  static let shared = WatchConnector()

  @Published var currentView: WatchViewState = .mainMenu

  private var authManager = AuthManager.shared
  private var checklistManager = ChecklistViewModel.shared
  private var galleryManager = GalleryManager.shared
  private var calendarManager = CalendarViewModel.shared
  private var connectionMonitorTimer: Timer?
  private var isMonitoringConnection = false

  private override init() {
    super.init()
    checklistManager.loadChecklistData()
    setupWatchConnectivity()
    startConnectionMonitoring()
  }

  deinit {
    stopConnectionMonitoring()
  }

  private func setupWatchConnectivity() {
    if WCSession.isSupported() {
      WCSession.default.delegate = self
      WCSession.default.activate()

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        self.loadLatestApplicationContext()
      }
    }
  }

  private func startConnectionMonitoring() {
    guard !isMonitoringConnection else { return }
    isMonitoringConnection = true

    connectionMonitorTimer = Timer.scheduledTimer(
      withTimeInterval: 15.0,
      repeats: true
    ) { [weak self] _ in
      self?.checkConnectionHealth()
    }
  }

  private func stopConnectionMonitoring() {
    connectionMonitorTimer?.invalidate()
    connectionMonitorTimer = nil
    isMonitoringConnection = false
  }

  private func checkConnectionHealth() {
    guard WCSession.isSupported() else { return }

    let session = WCSession.default

    if session.activationState != .activated {
      #if DEBUG
        print(
          "🔄 Watch: Session not activated, attempting to reactivate..."
        )
      #endif
      session.activate()
    } else if session.isReachable {
      loadLatestApplicationContext()
    }
  }

  func checkForCalendarUpdates() {
    loadLatestApplicationContext()
  }

  func forceReconnect() {
    guard WCSession.isSupported() else { return }

    let session = WCSession.default

    if session.activationState != .activated {
      #if DEBUG
        print("🔄 Watch: Reactivating session...")
      #endif
      session.activate()
    } else {
      sendWatchUUIDToiOS()
      loadLatestApplicationContext()
    }
  }

  private func loadLatestApplicationContext() {
    let context = WCSession.default.receivedApplicationContext

    #if DEBUG
      print("🔄 Watch: Loading latest application context on launch...")
      print("   → Context keys: \(context.keys)")
    #endif

    // Calendar data
    if let calendarDataString = context["calendarData"] as? String,
      let data = Data(base64Encoded: calendarDataString),
      let events = try? JSONDecoder().decode(
        [EventTransfer].self,
        from: data
      )
    {
      DispatchQueue.main.async {
        #if DEBUG
          print(
            "✅ Watch: Loaded calendar from stored context on launch"
          )
          print("   → \(events.count) events loaded")
        #endif
        self.calendarManager.updateEvents(events)
      }
    }

    // Checklist data
    if let checklistDataString = context["checklistData"] as? String,
      let data = Data(base64Encoded: checklistDataString)
    {
      DispatchQueue.main.async {
        let forceOverwrite = context["forceOverwrite"] as? Bool ?? false
        self.checklistManager.updateChecklistData(
          from: data,
          forceOverwrite: forceOverwrite
        )

        if let imageData = context["checklistImageData"]
          as? [String: String]
        {
          self.galleryManager.saveGalleryImages(imageData)
        }

        #if DEBUG
          print(
            "✅ Watch: Loaded checklist from stored context on launch"
          )
          print(
            "   → \(self.checklistManager.checklistData.checklists.count) checklists loaded"
          )
        #endif
      }
    }

    // Level data
    if let levelDataString = context["levelData"] as? String,
      let data = Data(base64Encoded: levelDataString)
    {
      DispatchQueue.main.async {
        self.handleLevelUpdate(data: data)

        #if DEBUG
          print(
            "✅ Watch: Loaded level data from stored context on launch"
          )
        #endif
      }
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
          ErrorLogger.log(
            "Watch WCSession activated with state: \(activationState.rawValue)"
          )
          ErrorLogger.log(
            "Watch session reachable: \(session.isReachable)"
          )
        #endif

        if activationState == .activated {
          self.sendWatchUUIDToiOS()
          self.loadLatestApplicationContext()
        }
      }
    }
  }

  private func sendWatchUUIDToiOS() {
    let watchUUID = WatchConfig.shared.uuid
    let message: [String: Any] = [
      "action": "updateWatchUUID",
      "watchUUID": watchUUID,
    ]

    #if DEBUG
      print(
        "⌚ Watch: Sending UUID to iOS: \(String(watchUUID.prefix(8)))"
      )
    #endif

    if WCSession.default.isReachable {
      WCSession.default.sendMessage(message, replyHandler: nil) { error in
        #if DEBUG
          print(
            "⌚ Watch: Failed to send UUID via message: \(error.localizedDescription)"
          )
        #endif
        do {
          try WCSession.default.updateApplicationContext(message)
          #if DEBUG
            print(
              "⌚ Watch: UUID sent via background context instead"
            )
          #endif
        } catch {
          #if DEBUG
            print(
              "⌚ Watch: Failed to send UUID via context: \(error.localizedDescription)"
            )
          #endif
        }
      }
    } else {
      do {
        try WCSession.default.updateApplicationContext(message)
        #if DEBUG
          print("⌚ Watch: UUID sent via background context")
        #endif
      } catch {
        #if DEBUG
          print(
            "⌚ Watch: Failed to send UUID: \(error.localizedDescription)"
          )
        #endif
      }
    }
  }

  func sessionReachabilityDidChange(_ session: WCSession) {
    #if DEBUG
      print("🔄 Watch: Reachability changed to \(session.isReachable)")
    #endif

    if session.isReachable {
      DispatchQueue.main.async {
        self.sendWatchUUIDToiOS()
        self.loadLatestApplicationContext()
      }
    }
  }

  func session(
    _ session: WCSession,
    didReceiveMessage message: [String: Any],
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
        case "returnToMainMenu", "returnToDashboard", "wakeUp":
          self.currentView = .mainMenu
          replyHandler(["status": "success"])
        case "updateChecklist":
          if let dataString = message["data"] as? String,
            let data = Data(base64Encoded: dataString)
          {
            let forceOverwrite =
              message["forceOverwrite"] as? Bool ?? false
            self.checklistManager.updateChecklistData(
              from: data,
              forceOverwrite: forceOverwrite
            )
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
                refreshToken: refreshToken
              )
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
            let events = try? JSONDecoder().decode(
              [EventTransfer].self,
              from: data
            )
          {
            self.calendarManager.updateEvents(events)
          }
          replyHandler(["status": "success"])
        case "updateLevel":
          if let dataString = message["data"] as? String,
            let data = Data(base64Encoded: dataString)
          {
            self.handleLevelUpdate(data: data)
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
        case "returnToMainMenu", "returnToDashboard", "wakeUp":
          self.currentView = .mainMenu
        case "updateChecklist":
          if let dataString = message["data"] as? String,
            let data = Data(base64Encoded: dataString)
          {
            let forceOverwrite =
              message["forceOverwrite"] as? Bool ?? false
            checklistManager.updateChecklistData(
              from: data,
              forceOverwrite: forceOverwrite
            )
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
                refreshToken: refreshToken
              )
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
            let events = try? JSONDecoder().decode(
              [EventTransfer].self,
              from: data
            )
          {
            self.calendarManager.updateEvents(events)
          }
        case "updateLevel":
          if let dataString = message["data"] as? String,
            let data = Data(base64Encoded: dataString)
          {
            self.handleLevelUpdate(data: data)
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

    #if DEBUG
      print("📲 Watch: Received application context update")
      print(
        "   → Timestamp: \(applicationContext["timestamp"] ?? "unknown")"
      )
    #endif

    DispatchQueue.main.async {
      // Calendar data
      if let calendarDataString = applicationContext["calendarData"]
        as? String,
        let data = Data(base64Encoded: calendarDataString),
        let events = try? JSONDecoder().decode(
          [EventTransfer].self,
          from: data
        )
      {
        #if DEBUG
          print("✅ Watch: Calendar updated from background context")
          print("   → \(events.count) events received")
        #endif
        self.calendarManager.updateEvents(events)
      }

      // Checklist data
      if let checklistDataString = applicationContext["checklistData"]
        as? String,
        let data = Data(base64Encoded: checklistDataString)
      {
        let forceOverwrite =
          applicationContext["forceOverwrite"] as? Bool ?? false
        self.checklistManager.updateChecklistData(
          from: data,
          forceOverwrite: forceOverwrite
        )

        if let imageData = applicationContext["checklistImageData"]
          as? [String: String]
        {
          self.galleryManager.saveGalleryImages(imageData)
        }

        #if DEBUG
          print("✅ Watch: Checklist updated from background context")
          print(
            "   → \(self.checklistManager.checklistData.checklists.count) checklists received"
          )
        #endif
      }

      // Level data
      if let levelDataString = applicationContext["levelData"] as? String,
        let data = Data(base64Encoded: levelDataString)
      {
        self.handleLevelUpdate(data: data)
        #if DEBUG
          print("✅ Watch: Level updated from background context")
        #endif
      }

      // App configurations
      if let configDataString = applicationContext["appConfigurations"] as? String,
        let data = Data(base64Encoded: configDataString)
      {
        self.handleConfigurationsUpdate(from: applicationContext)
        #if DEBUG
          print("✅ Watch: App configurations updated from background context")
        #endif
      }

      // Legacy action-based handling (for backward compatibility)
      if let action = applicationContext["action"] as? String {
        switch action {
        case "wakeUp":
          self.currentView = .mainMenu
        case "updateChecklist":
          if let dataString = applicationContext["data"] as? String,
            let data = Data(base64Encoded: dataString)
          {
            let forceOverwrite =
              applicationContext["forceOverwrite"] as? Bool
              ?? false
            self.checklistManager.updateChecklistData(
              from: data,
              forceOverwrite: forceOverwrite
            )

            if let imageData = applicationContext["imageData"]
              as? [String: String]
            {
              self.galleryManager.saveGalleryImages(imageData)
            }

            #if DEBUG
              print(
                "✅ Watch: Checklist updated from background context"
              )
            #endif
          }
        case "updateTelemetry":
          if let hasConsent = applicationContext["hasConsent"]
            as? Bool
          {
            TelemetryManager.shared.hasConsent = hasConsent
            #if DEBUG
              ErrorLogger.log(
                "Telemetry consent updated via background transfer: \(hasConsent)"
              )
            #endif
          }
        case "updateLevel":
          if let dataString = applicationContext["data"] as? String,
            let data = Data(base64Encoded: dataString)
          {
            self.handleLevelUpdate(data: data)
            #if DEBUG
              print(
                "✅ Watch: Level updated from background context"
              )
            #endif
          }
        default:
          #if DEBUG
            ErrorLogger.log(
              "Unknown action in application context: \(action)"
            )
          #endif
        }
      }
    }
  }

  func session(
    _ session: WCSession,
    didReceiveUserInfo userInfo: [String: Any] = [:]
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
        case "updateChecklist":
          if let dataString = userInfo["data"] as? String,
            let data = Data(base64Encoded: dataString)
          {
            let forceOverwrite =
              userInfo["forceOverwrite"] as? Bool ?? false
            self.checklistManager.updateChecklistData(
              from: data,
              forceOverwrite: forceOverwrite
            )

            if let imageData = userInfo["imageData"]
              as? [String: String]
            {
              self.galleryManager.saveGalleryImages(imageData)
            }

            #if DEBUG
              ErrorLogger.log(
                "✅ Checklist updated via background transfer (userInfo)"
              )
            #endif
          }
        case "updateTelemetry":
          if let hasConsent = userInfo["hasConsent"] as? Bool {
            TelemetryManager.shared.hasConsent = hasConsent
            #if DEBUG
              ErrorLogger.log(
                "Telemetry consent updated via background transfer: \(hasConsent)"
              )
            #endif
          }
        case "updateLevel":
          if let dataString = userInfo["data"] as? String,
            let data = Data(base64Encoded: dataString)
          {
            self.handleLevelUpdate(data: data)
            #if DEBUG
              ErrorLogger.log(
                "✅ Level updated via background transfer (userInfo)"
              )
            #endif
          }
        default:
          #if DEBUG
            ErrorLogger.log(
              "Unknown action in user info: \(action)"
            )
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
