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

  func resetWatchConnectivity() {
    guard WCSession.isSupported() else { return }

    #if DEBUG
      print("Resetting Watch Connectivity...")
    #endif

    if WCSession.default.activationState == .activated {
      WCSession.default.delegate = nil
    }

    DispatchQueue.main.asyncAfter(
      deadline: .now() + AppConstants.Timing.mediumDelay
    ) {
      WCSession.default.delegate = self
      WCSession.default.activate()

      DispatchQueue.main.asyncAfter(
        deadline: .now() + AppConstants.Timing.longDelay
      ) {
        self.isConnected =
          WCSession.default.activationState == .activated
          && WCSession.default.isReachable

        #if DEBUG
          print("Reset complete - Connected: \(self.isConnected)")
          print(
            "Activation State: \(WCSession.default.activationState.rawValue)"
          )
          print("Is Reachable: \(WCSession.default.isReachable)")
          print("Is Paired: \(WCSession.default.isPaired)")
          print(
            "Is Watch App Installed: \(WCSession.default.isWatchAppInstalled)"
          )
        #endif
      }
    }
  }

  func forceReconnect() {
    guard WCSession.isSupported() else { return }

    if WCSession.default.activationState != .activated {
      WCSession.default.activate()
      return
    }

    DispatchQueue.main.async {
      self.isConnected =
        WCSession.default.activationState == .activated
        && WCSession.default.isReachable

      if self.isConnected {
        self.syncChecklistToWatch()
        self.sendWakeUpMessage()
        self.syncTelemetryToWatch()
        self.syncCalendarToWatch()
      }
    }
  }

}
