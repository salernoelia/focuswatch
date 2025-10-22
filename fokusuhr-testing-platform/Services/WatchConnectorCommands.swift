import WatchConnectivity

extension WatchConnector {
  func switchToApp(index: Int) {
    guard WCSession.default.activationState == .activated else {
      #if DEBUG
        print("Session not activated for switchToApp")
      #endif
      return
    }

    guard WCSession.default.isReachable else {
      lastError = .watchNotReachable
      #if DEBUG
        print("Watch not reachable for switchToApp")
      #endif
      return
    }

    let message =
      ["action": "switchToApp", "appIndex": index] as [String: Any]
    WCSession.default.sendMessage(message, replyHandler: nil) { error in
      let appError = AppError.watchMessageFailed(underlying: error)
      #if DEBUG
        ErrorLogger.log(appError)
      #endif
      self.lastError = appError
    }
  }

  func returnToMainMenu() {
    guard WCSession.default.activationState == .activated else {
      #if DEBUG
        print("Session not activated for returnToMainMenu")
      #endif
      return
    }

    guard WCSession.default.isReachable else {
      lastError = .watchNotReachable
      #if DEBUG
        print("Watch not reachable for returnToMainMenu")
      #endif
      return
    }

    let message = ["action": "returnToMainMenu"]
    WCSession.default.sendMessage(message, replyHandler: nil) { error in
      let appError = AppError.watchMessageFailed(underlying: error)
      #if DEBUG
        ErrorLogger.log(appError)
      #endif
      self.lastError = appError
    }
  }

  func sendWakeUpMessage() {
    guard WCSession.default.activationState == .activated else {
      #if DEBUG
        print("Session not activated for wakeUp")
      #endif
      return
    }

    guard WCSession.default.isReachable else {
      lastError = .watchNotReachable
      return
    }

    let message = ["action": "wakeUp"]
    WCSession.default.sendMessage(
      message,
      replyHandler: { _ in
        #if DEBUG
          print("Wake up message sent successfully")
        #endif
        self.syncAuthToWatch()
      }
    ) { error in
      let appError = AppError.watchMessageFailed(underlying: error)
      #if DEBUG
        ErrorLogger.log(appError)
      #endif
      self.lastError = appError
    }
  }

}
