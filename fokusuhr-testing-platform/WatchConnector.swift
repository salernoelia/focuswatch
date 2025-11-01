import Foundation
import WatchConnectivity

class WatchConnector: NSObject, ObservableObject, WCSessionDelegate {
  @Published var isConnected = false
  @Published var checklistData = ChecklistData.default
  @Published var lastError: AppError?
  public var lastSyncedHash: Int?
  public var lastCalendarSyncHash: Int?
  public var isSyncing = false
  static let shared = WatchConnector()

  private var connectionMonitorTimer: Timer?
  public var reconnectAttempts = 0
  private let maxReconnectAttempts = 5
  private var isMonitoringConnection = false

  override init() {
    super.init()
    loadChecklistData()
    loadWatchUUIDFromContext()
    setupWatchConnectivity()
    startConnectionMonitoring()
  }
  
  public func loadWatchUUIDFromContext() {
    guard WCSession.isSupported() else { return }
    let context = WCSession.default.receivedApplicationContext
    if let watchUUID = context["watchUUID"] as? String {
      WatchConfig.shared.setConnectedWatchUUID(watchUUID)
      #if DEBUG
        print("📱 iOS: Loaded Watch UUID from context: \(String(watchUUID.prefix(8)))")
      #endif
    }
  }

  deinit {
    stopConnectionMonitoring()
  }

  func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    DispatchQueue.main.async {
      self.isConnected = activationState == .activated

      if let error = error {
        let appError = AppError.watchMessageFailed(underlying: error)
        #if DEBUG
          ErrorLogger.log(appError)
        #endif
        self.lastError = appError
        self.scheduleReconnectIfNeeded()
      } else {
        #if DEBUG
          print("WCSession activated with state: \(activationState.rawValue)")
          print("Is Reachable: \(session.isReachable)")
          print("Is Paired: \(session.isPaired)")
          print("Is Watch App Installed: \(session.isWatchAppInstalled)")
        #endif
        self.reconnectAttempts = 0
      }

      if self.isConnected {
        self.syncAllDataToWatch()
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
        print("WCSession deactivated, reactivating...")
      #endif
    }

    session.activate()
  }

  func sessionReachabilityDidChange(_ session: WCSession) {
    #if DEBUG
      print("WCSession reachability changed: \(session.isReachable)")
    #endif

    if session.isReachable {
      DispatchQueue.main.async {
        self.reconnectAttempts = 0
        self.syncChecklistToWatch()
        self.syncAuthToWatch()
      }
    }
  }

  private func syncAllDataToWatch() {
    syncChecklistToWatch()
    syncAuthToWatch()
    syncTelemetryToWatch()
    syncCalendarToWatch()
  }

  private func startConnectionMonitoring() {
    guard !isMonitoringConnection else { return }
    isMonitoringConnection = true

    connectionMonitorTimer = Timer.scheduledTimer(
      withTimeInterval: 10.0,
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
    let shouldBeConnected = session.activationState == .activated

    if shouldBeConnected != isConnected {
      DispatchQueue.main.async {
        self.isConnected = shouldBeConnected

        #if DEBUG
          print("Connection state corrected: \(shouldBeConnected)")
        #endif

        if shouldBeConnected {
          self.reconnectAttempts = 0
          self.syncChecklistToWatch()
          self.syncCalendarToWatch()
          self.syncTelemetryToWatch()
        }
      }
    }

    if !isConnected && session.activationState != .activated {
      scheduleReconnectIfNeeded()
    }
  }

  public func scheduleReconnectIfNeeded() {
    guard reconnectAttempts < maxReconnectAttempts else {
      #if DEBUG
        print("Max reconnect attempts reached")
      #endif
      return
    }

    reconnectAttempts += 1
    let delay = min(Double(reconnectAttempts) * 2.0, 10.0)

    #if DEBUG
      print("Scheduling reconnect attempt \(reconnectAttempts) in \(delay)s")
    #endif

    DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
      self?.attemptReconnect()
    }
  }

  private func attemptReconnect() {
    guard WCSession.isSupported() else { return }

    let session = WCSession.default

    if session.activationState != .activated {
      #if DEBUG
        print("Attempting to reactivate session...")
      #endif
      session.activate()
    } else {
      DispatchQueue.main.async {
        self.isConnected = true
        self.reconnectAttempts = 0
        self.syncChecklistToWatch()
        self.syncCalendarToWatch()
        self.syncTelemetryToWatch()
      }
    }
  }

}
