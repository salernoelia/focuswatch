import Combine
import Foundation
import WatchConnectivity

enum WatchViewState {
    case mainMenu
    case app(Int)
}

final class SyncCoordinator: ObservableObject {
    static let shared = SyncCoordinator()

    @Published var currentView: WatchViewState = .mainMenu
    @Published private(set) var isSyncing = false
    @Published private(set) var syncStatus: String = SyncConstants.Status.pending

    let transport: ConnectivityTransport

    private let checklistManager = ChecklistViewModel.shared
    private let galleryManager = GalleryManager.shared
    private let calendarManager = CalendarViewModel.shared
    private let authManager = AuthManager.shared

    private var cancellables = Set<AnyCancellable>()
    private var validationTimer: Timer?
    private var pendingValidation = false
    private var lastValidationTime: Date?

    init(transport: ConnectivityTransport = .shared) {
        self.transport = transport
        setupObservers()
        startValidationTimer()
    }

    private func setupObservers() {
        transport.contextReceived
            .receive(on: DispatchQueue.main)
            .sink { [weak self] context in
                self?.handleApplicationContext(context)
            }
            .store(in: &cancellables)

        transport.messageReceived
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message, replyHandler in
                self?.handleMessage(message, replyHandler: replyHandler)
            }
            .store(in: &cancellables)

        transport.userInfoReceived
            .receive(on: DispatchQueue.main)
            .sink { [weak self] userInfo in
                self?.handleUserInfo(userInfo)
            }
            .store(in: &cancellables)

        transport.fileReceived
            .receive(on: DispatchQueue.main)
            .sink { [weak self] fileURL, metadata in
                self?.handleReceivedFile(fileURL: fileURL, metadata: metadata)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: Notification.Name.checklistDataChanged)
            .debounce(for: .seconds(3), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.validateCurrentSync()
            }
            .store(in: &cancellables)
    }

    private func startValidationTimer() {
        validationTimer = Timer.scheduledTimer(
            withTimeInterval: SyncConstants.Timing.verificationInterval,
            repeats: true
        ) { [weak self] _ in
            self?.validateCurrentSync()
        }
    }

    private func validateCurrentSync() {
        let requiredImages = Set(
            checklistManager.checklistData.checklists.flatMap { checklist in
                checklist.items.compactMap { item in
                    item.imageName.isEmpty ? nil : item.imageName
                }
            }
        )

        guard !requiredImages.isEmpty else {
            syncStatus = SyncConstants.Status.complete
            return
        }

        var missingImages: [String] = []
        for imageName in requiredImages {
            if !galleryManager.imageExists(imageName) {
                missingImages.append(imageName)
            }
        }

        if missingImages.isEmpty {
            syncStatus = SyncConstants.Status.complete
            lastValidationTime = nil
        } else if missingImages.count == requiredImages.count {
            syncStatus = SyncConstants.Status.pending
        } else {
            syncStatus = SyncConstants.Status.partial
        }

        if !missingImages.isEmpty && transport.isReachable && !pendingValidation {
            if let lastValidation = lastValidationTime,
               Date().timeIntervalSince(lastValidation) < 15.0 {
                #if DEBUG
                    print("Watch SyncCoordinator: Throttling validation - too soon since last request")
                #endif
                return
            }

            #if DEBUG
                print("Watch SyncCoordinator: Validation found \(missingImages.count) missing images")
            #endif
            lastValidationTime = Date()
            pendingValidation = true
            galleryManager.requestMissingImages(missingImages)
            DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) { [weak self] in
                self?.pendingValidation = false
            }
        }
    }

    func forceReconnect() {
        transport.forceReconnect()
    }

    func checkForCalendarUpdates() {
        transport.loadLatestApplicationContext()
    }

    func forceSync() {
        isSyncing = true
        syncStatus = SyncConstants.Status.pending
        lastValidationTime = nil
        pendingValidation = false

        let message: [String: Any] = [
            SyncConstants.Keys.action: SyncConstants.Actions.forceSync,
            SyncConstants.Keys.timestamp: Date().timeIntervalSince1970
        ]

        if transport.isReachable {
            transport.sendMessage(message, replyHandler: { [weak self] _ in
                DispatchQueue.main.async {
                    self?.transport.loadLatestApplicationContext()
                }
            }, errorHandler: { [weak self] _ in
                DispatchQueue.main.async {
                    self?.isSyncing = false
                }
            })
        } else {
            transport.transferUserInfo(message)
            transport.loadLatestApplicationContext()
            isSyncing = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            self?.validateCurrentSync()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) { [weak self] in
            self?.isSyncing = false
        }
    }

    private func handleApplicationContext(_ context: [String: Any]) {
        #if DEBUG
            ErrorLogger.log("Watch: Received applicationContext")
            ErrorLogger.log("Watch: Context keys: \(context.keys.joined(separator: ", "))")
        #endif

        isSyncing = true

        if let calendarDataBytes = context[SyncConstants.Keys.calendarData] as? Data,
           let events = try? JSONDecoder().decode([EventTransfer].self, from: calendarDataBytes)
        {
          updateCalendarEvents(events)
        } else if let calendarDataString = context[SyncConstants.Keys.calendarData] as? String,
                  let data = Data(base64Encoded: calendarDataString),
                  let events = try? JSONDecoder().decode([EventTransfer].self, from: data)
        {
          updateCalendarEvents(events)
        }

        var checklistUpdated = false

        if let checklistDataBytes = context[SyncConstants.Keys.checklistData] as? Data {
            let forceOverwrite = context[SyncConstants.Keys.forceOverwrite] as? Bool ?? false

            #if DEBUG
                ErrorLogger.log("Watch: Processing checklist data (forceOverwrite: \(forceOverwrite), size: \(checklistDataBytes.count) bytes)")
                if let decodedData = try? JSONDecoder().decode(ChecklistData.self, from: checklistDataBytes) {
                    ErrorLogger.log("Watch: Decoded \(decodedData.checklists.count) checklists from context")
                    for (index, checklist) in decodedData.checklists.enumerated() {
                        ErrorLogger.log("Watch:   [\(index)] \(checklist.name) - \(checklist.items.count) items")
                    }
                }
            #endif

            if let imageData = context[SyncConstants.Keys.checklistImageData] as? [String: String], !imageData.isEmpty {
                #if DEBUG
                    ErrorLogger.log("Watch: Saving \(imageData.count) gallery images from context")
                #endif
                galleryManager.saveGalleryImages(imageData)
            } else {
                #if DEBUG
                    ErrorLogger.log("Watch: No images in context payload")
                #endif
            }

            checklistManager.updateChecklistData(from: checklistDataBytes, forceOverwrite: forceOverwrite)
            checklistUpdated = true
        } else if let checklistDataString = context[SyncConstants.Keys.checklistData] as? String,
                  let data = Data(base64Encoded: checklistDataString)
        {
            let forceOverwrite = context[SyncConstants.Keys.forceOverwrite] as? Bool ?? false

            #if DEBUG
                ErrorLogger.log("Watch: Processing base64 checklist data (forceOverwrite: \(forceOverwrite))")
            #endif

            if let imageData = context[SyncConstants.Keys.checklistImageData] as? [String: String], !imageData.isEmpty {
                #if DEBUG
                    ErrorLogger.log("Watch: Saving \(imageData.count) gallery images from base64 context")
                #endif
                galleryManager.saveGalleryImages(imageData)
            } else {
                #if DEBUG
                    ErrorLogger.log("Watch: No images in base64 context payload")
                #endif
            }

            checklistManager.updateChecklistData(from: data, forceOverwrite: forceOverwrite)
            checklistUpdated = true
        }

        if checklistUpdated {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.validateCurrentSync()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) { [weak self] in
                self?.isSyncing = false
            }
        } else {
            isSyncing = false
        }

    if let levelDataBytes = context[SyncConstants.Keys.levelData] as? Data {
      handleLevelUpdate(data: levelDataBytes)
    } else if let levelDataString = context[SyncConstants.Keys.levelData] as? String,
      let data = Data(base64Encoded: levelDataString)
    {
      handleLevelUpdate(data: data)
    }

    if let configDataBytes = context[SyncConstants.Keys.appConfigurations] as? Data {
      handleConfigurationsUpdate(data: configDataBytes)
    } else if let configDataString = context[SyncConstants.Keys.appConfigurations] as? String,
      let data = Data(base64Encoded: configDataString)
    {
      handleConfigurationsUpdate(data: data)
    }

    if let action = context[SyncConstants.Keys.action] as? String {
      handleLegacyAction(action, context: context)
    }
  }

  private func handleMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)?) {
    guard let action = message[SyncConstants.Keys.action] as? String else {
      replyHandler?([SyncConstants.Keys.status: SyncConstants.Status.noAction])
      return
    }

    switch action {
    case SyncConstants.Actions.switchToApp:
      currentView = .mainMenu
      if let appIndex = message[SyncConstants.Keys.appIndex] as? Int {
        currentView = .app(appIndex)
      }

    case SyncConstants.Actions.returnToDashboard, SyncConstants.Actions.wakeUp:
      currentView = .mainMenu

    case SyncConstants.Actions.updateChecklist:
      if let dataString = message[SyncConstants.Keys.data] as? String,
        let data = Data(base64Encoded: dataString)
      {
        let forceOverwrite = message[SyncConstants.Keys.forceOverwrite] as? Bool ?? false
        checklistManager.updateChecklistData(from: data, forceOverwrite: forceOverwrite)
      }
      if let imageData = message[SyncConstants.Keys.imageData] as? [String: String] {
        galleryManager.saveGalleryImages(imageData)
      }

    case SyncConstants.Actions.updateAuth:
      if let isLoggedIn = message[SyncConstants.Keys.isLoggedIn] as? Bool {
        if isLoggedIn,
          let accessToken = message[SyncConstants.Keys.accessToken] as? String,
          let refreshToken = message[SyncConstants.Keys.refreshToken] as? String
        {
          authManager.updateAuthState(accessToken: accessToken, refreshToken: refreshToken)
        } else {
          authManager.clearAuthState()
        }
      }

    case SyncConstants.Actions.updateTelemetry:
      if let hasConsent = message[SyncConstants.Keys.hasConsent] as? Bool {
        TelemetryManager.shared.hasConsent = hasConsent
      }

    case SyncConstants.Actions.updateCalendar:
      if let dataString = message[SyncConstants.Keys.data] as? String,
        let data = Data(base64Encoded: dataString),
        let events = try? JSONDecoder().decode([EventTransfer].self, from: data)
      {
        updateCalendarEvents(events)
      }

    case SyncConstants.Actions.updateLevel:
      if let dataString = message[SyncConstants.Keys.data] as? String,
        let data = Data(base64Encoded: dataString)
      {
        handleLevelUpdate(data: data)
      }

    case SyncConstants.Actions.resetChecklistState:
      if let checklistIdString = message[SyncConstants.Keys.checklistId] as? String,
        let checklistId = UUID(uuidString: checklistIdString)
      {
        ChecklistProgressManager.shared.clearProgressAndCompletion(for: checklistId)
      }

    default:
      replyHandler?([SyncConstants.Keys.status: SyncConstants.Status.unknownAction])
      return
    }

    replyHandler?([SyncConstants.Keys.status: SyncConstants.Status.success])
  }

  private func handleUserInfo(_ userInfo: [String: Any]) {
    guard let action = userInfo[SyncConstants.Keys.action] as? String else { return }

    switch action {
    case SyncConstants.Actions.updateChecklist:
      if let dataString = userInfo[SyncConstants.Keys.data] as? String,
        let data = Data(base64Encoded: dataString)
      {
        let forceOverwrite = userInfo[SyncConstants.Keys.forceOverwrite] as? Bool ?? false
        checklistManager.updateChecklistData(from: data, forceOverwrite: forceOverwrite)
      }
      if let imageData = userInfo[SyncConstants.Keys.imageData] as? [String: String] {
        galleryManager.saveGalleryImages(imageData)
      }

    case SyncConstants.Actions.resetChecklistState:
      if let checklistIdString = userInfo[SyncConstants.Keys.checklistId] as? String,
        let checklistId = UUID(uuidString: checklistIdString)
      {
        ChecklistProgressManager.shared.clearProgressAndCompletion(for: checklistId)
      }

    case SyncConstants.Actions.updateTelemetry:
      if let hasConsent = userInfo[SyncConstants.Keys.hasConsent] as? Bool {
        TelemetryManager.shared.hasConsent = hasConsent
      }

    case SyncConstants.Actions.updateLevel:
      if let dataString = userInfo[SyncConstants.Keys.data] as? String,
        let data = Data(base64Encoded: dataString)
      {
        handleLevelUpdate(data: data)
      }

    default:
      break
    }
  }

  private func handleLegacyAction(_ action: String, context: [String: Any]) {
    switch action {
    case SyncConstants.Actions.wakeUp:
      currentView = .mainMenu

    case SyncConstants.Actions.updateChecklist:
      if let dataString = context[SyncConstants.Keys.data] as? String,
        let data = Data(base64Encoded: dataString)
      {
        let forceOverwrite = context[SyncConstants.Keys.forceOverwrite] as? Bool ?? false
        checklistManager.updateChecklistData(from: data, forceOverwrite: forceOverwrite)
      }
      if let imageData = context[SyncConstants.Keys.imageData] as? [String: String] {
        galleryManager.saveGalleryImages(imageData)
      }

    case SyncConstants.Actions.updateTelemetry:
      if let hasConsent = context[SyncConstants.Keys.hasConsent] as? Bool {
        TelemetryManager.shared.hasConsent = hasConsent
      }

    case SyncConstants.Actions.updateLevel:
      if let dataString = context[SyncConstants.Keys.data] as? String,
        let data = Data(base64Encoded: dataString)
      {
        handleLevelUpdate(data: data)
      }

    default:
      break
    }
  }

  private func updateCalendarEvents(_ events: [EventTransfer]) {
    Task { @MainActor in
      calendarManager.updateEvents(events)
    }
  }

  private func handleLevelUpdate(data: Data) {
    do {
      let levelData = try JSONDecoder().decode(LevelData.self, from: data)
      saveLevelMilestones(levelData.milestones)
      NotificationCenter.default.post(
        name: NSNotification.Name("LevelMilestonesUpdated"), object: nil)
    } catch {
      #if DEBUG
        ErrorLogger.log(AppError.decodingFailed(type: "level data", underlying: error))
      #endif
    }
  }

  private func saveLevelMilestones(_ milestones: [LevelMilestone]) {
    do {
      let data = try JSONEncoder().encode(milestones)
      UserDefaults.standard.set(data, forKey: "levelMilestones")
    } catch {
      #if DEBUG
        ErrorLogger.log(AppError.encodingFailed(type: "level milestones", underlying: error))
      #endif
    }
  }

  func loadLevelMilestones() -> [LevelMilestone] {
    guard let data = UserDefaults.standard.data(forKey: "levelMilestones") else {
      return []
    }

    do {
      return try JSONDecoder().decode([LevelMilestone].self, from: data)
    } catch {
      #if DEBUG
        ErrorLogger.log(AppError.decodingFailed(type: "level milestones", underlying: error))
      #endif
      return []
    }
  }

  func syncLevelToiOS() {
    Task { @MainActor in
      guard let progress = LevelService.shared.currentProgress else { return }

      let levelData = LevelData(
        currentLevel: progress.currentLevel,
        currentXP: progress.currentXP,
        totalXP: progress.totalXP,
        milestones: loadLevelMilestones(),
        lastUpdated: progress.lastUpdated
      )

      do {
        let data = try JSONEncoder().encode(levelData)
        let message: [String: Any] = [
          SyncConstants.Keys.action: SyncConstants.Actions.syncLevelFromWatch,
          SyncConstants.Keys.data: data.base64EncodedString(),
          SyncConstants.Keys.timestamp: Date().timeIntervalSince1970,
        ]

        guard WCSession.default.activationState == .activated else { return }

        do {
          try transport.updateApplicationContext(message)
        } catch {}

        if WCSession.default.isReachable {
          transport.sendMessage(message, replyHandler: nil, errorHandler: nil)
        }

        transport.transferUserInfo(message)
      } catch {
        #if DEBUG
          ErrorLogger.log(AppError.encodingFailed(type: "level data", underlying: error))
        #endif
      }
    }
  }

  func requestLevelDataFromiOS() {
    guard WCSession.default.activationState == .activated else { return }

    let message: [String: Any] = [
      SyncConstants.Keys.action: SyncConstants.Actions.requestLevelData,
      SyncConstants.Keys.timestamp: Date().timeIntervalSince1970,
    ]

    if WCSession.default.isReachable {
      transport.sendMessage(message, replyHandler: nil, errorHandler: nil)
    }
  }

  private func handleConfigurationsUpdate(data: Data) {
    do {
      let configurations = try JSONDecoder().decode(AppConfigurations.self, from: data)
      UserDefaults.standard.set(data, forKey: "appConfigurations")
      NotificationCenter.default.post(name: .appConfigurationsUpdated, object: configurations)
    } catch {
      #if DEBUG
        ErrorLogger.log(AppError.decodingFailed(type: "app configurations", underlying: error))
      #endif
    }
  }

  private func handleReceivedFile(fileURL: URL, metadata: [String: Any]?) {
    #if DEBUG
      print("Watch SyncCoordinator: Received file transfer at: \(fileURL.path)")
      print("Watch SyncCoordinator: Metadata: \(String(describing: metadata))")
      if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
         let fileSize = attributes[.size] as? Int64 {
        print("Watch SyncCoordinator: File size: \(fileSize) bytes")
      }
    #endif

    guard let metadata = metadata,
      let syncType = metadata[SyncConstants.Keys.syncType] as? String
    else {
      #if DEBUG
        print("Watch SyncCoordinator: No syncType in metadata, ignoring")
      #endif
      return
    }

    #if DEBUG
      print("Watch SyncCoordinator: SyncType: \(syncType)")
      if let imageName = metadata[SyncConstants.Keys.imageName] as? String {
        print("Watch SyncCoordinator: Image name: \(imageName)")
      }
    #endif

    switch syncType {
    case SyncMessageType.checklist.rawValue:
      galleryManager.handleReceivedFile(fileURL: fileURL, metadata: metadata)
    default:
      #if DEBUG
        print("Watch SyncCoordinator: Unknown syncType: \(syncType)")
      #endif
      break
    }
  }

  static func loadAppConfigurations() -> AppConfigurations {
    guard let data = UserDefaults.standard.data(forKey: "appConfigurations") else {
      return AppConfigurations.default
    }

    do {
      return try JSONDecoder().decode(AppConfigurations.self, from: data)
    } catch {
      return AppConfigurations.default
    }
  }
}

extension Notification.Name {
    static let appConfigurationsUpdated = Notification.Name("appConfigurationsUpdated")
}
