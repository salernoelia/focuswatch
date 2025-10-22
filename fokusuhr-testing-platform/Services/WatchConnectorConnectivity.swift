import WatchConnectivity

extension WatchConnector {
  func setupWatchConnectivity() {
    guard WCSession.isSupported() else {
      lastError = .watchNotSupported
      #if DEBUG
        ErrorLogger.log(.watchNotSupported)
      #endif
      return
    }

    WCSession.default.delegate = self
    WCSession.default.activate()
  }

  func forceReconnect() {
    guard WCSession.isSupported() else { return }

    let session = WCSession.default

    if session.activationState != .activated {
      #if DEBUG
        print("Activating session...")
      #endif
      session.activate()
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      self.isConnected = session.activationState == .activated

      #if DEBUG
        print("Reconnect complete - Connected: \(self.isConnected)")
        print("Activation State: \(session.activationState.rawValue)")
        print("Is Reachable: \(session.isReachable)")
        print("Is Paired: \(session.isPaired)")
        print("Is Watch App Installed: \(session.isWatchAppInstalled)")
      #endif

      if self.isConnected {
        self.reconnectAttempts = 0
        self.syncChecklistToWatch()
        self.syncCalendarToWatch()
        self.syncTelemetryToWatch()

        if session.isReachable {
          self.sendWakeUpMessage()
        }
      } else {
        self.scheduleReconnectIfNeeded()
      }
    }
  }

}
