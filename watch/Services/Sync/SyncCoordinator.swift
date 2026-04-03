import Combine
import Foundation
import WatchConnectivity

enum WatchViewState {
    case mainMenu
    case app(Int)
}

@MainActor
final class SyncCoordinator: ObservableObject {
    static let shared = SyncCoordinator()

    @Published var currentView: WatchViewState = .mainMenu
    @Published private(set) var isSyncing = false
    @Published private(set) var syncStatus: String = SyncConstants.Status.pending
    @Published private(set) var syncProgress: Double = 0

    let transport: ConnectivityTransport
    private let incomingMessageRouter: IncomingMessageRouter
    private let incomingContextHandler: IncomingContextHandler
    private let incomingFileHandler: IncomingFileHandler
    private let syncValidationService: SyncValidationService

    private let checklistManager: ChecklistViewModel
    private let galleryManager: GalleryManager
    private let calendarManager: CalendarViewModel
    private let telemetryManager: TelemetryManager
    private let checklistProgressManager: ChecklistProgressManager

    private var cancellables = Set<AnyCancellable>()
    private var validationTimer: Timer?

    init(
        transport: ConnectivityTransport = .shared,
        checklistManager: ChecklistViewModel = .shared,
        galleryManager: GalleryManager = .shared,
        calendarManager: CalendarViewModel = .shared,
        authManager: AuthManager = .shared,
        telemetryManager: TelemetryManager = .shared,
        checklistProgressManager: ChecklistProgressManager = .shared
    ) {
        self.transport = transport
        self.checklistManager = checklistManager
        self.galleryManager = galleryManager
        self.calendarManager = calendarManager
        self.telemetryManager = telemetryManager
        self.checklistProgressManager = checklistProgressManager
        self.incomingContextHandler = IncomingContextHandler(
            checklistManager: checklistManager,
            galleryManager: galleryManager
        )
        self.incomingFileHandler = IncomingFileHandler(galleryManager: galleryManager)
        self.syncValidationService = SyncValidationService()
        self.incomingMessageRouter = IncomingMessageRouter(
            checklistManager: checklistManager,
            galleryManager: galleryManager,
            authManager: authManager,
            telemetryManager: telemetryManager,
            checklistProgressManager: checklistProgressManager
        )
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
                self?.handleIncomingMessage(message, replyHandler: replyHandler)
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
            Task { @MainActor in
                self?.validateCurrentSync()
            }
        }
    }

    private func validateCurrentSync() {
        let validationResult = syncValidationService.validate(
            checklistData: checklistManager.checklistData,
            transportReachable: transport.isReachable,
            imageExists: { [galleryManager] imageName in
                galleryManager.imageExists(imageName)
            },
            requestMissingImages: { [galleryManager] missingImages in
                galleryManager.requestMissingImages(missingImages)
            }
        )
        syncStatus = validationResult.status
        syncProgress = validationResult.progress
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
        syncProgress = 0
        syncValidationService.reset()

        let message: [String: Any] = [
            SyncConstants.Keys.action: SyncConstants.Actions.forceSync,
            SyncConstants.Keys.timestamp: Date().timeIntervalSince1970,
        ]

        if transport.isReachable {
            transport.sendMessage(
                message,
                replyHandler: { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.transport.loadLatestApplicationContext()
                    }
                },
                errorHandler: { [weak self] _ in
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
        isSyncing = true
        let checklistUpdated = incomingContextHandler.handle(
            context,
            updateCalendarEvents: { [weak self] events in
                self?.updateCalendarEvents(events)
            },
            handleLevelUpdate: { [weak self] data in
                self?.handleLevelUpdate(data: data)
            },
            handleConfigurationsUpdate: { [weak self] data in
                self?.handleConfigurationsUpdate(data: data)
            },
            handleLegacyAction: { [weak self] action, actionContext in
                self?.handleLegacyAction(action, context: actionContext)
            }
        )

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
    }

    private func handleIncomingMessage(
        _ message: [String: Any], replyHandler: (([String: Any]) -> Void)?
    ) {
        incomingMessageRouter.handle(
            message: message,
            replyHandler: replyHandler,
            setCurrentView: { [weak self] view in
                self?.currentView = view
            },
            updateCalendarEvents: { [weak self] events in
                self?.updateCalendarEvents(events)
            },
            handleLevelUpdate: { [weak self] data in
                self?.handleLevelUpdate(data: data)
            }
        )
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
                checklistProgressManager.clearProgressAndCompletion(for: checklistId)
            }

        case SyncConstants.Actions.updateTelemetry:
            if let hasConsent = userInfo[SyncConstants.Keys.hasConsent] as? Bool {
                telemetryManager.hasConsent = hasConsent
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
                telemetryManager.hasConsent = hasConsent
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
                ErrorLogger.log(
                    AppError.encodingFailed(type: "level milestones", underlying: error))
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
                ErrorLogger.log(
                    AppError.decodingFailed(type: "level milestones", underlying: error))
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
                ErrorLogger.log(
                    AppError.decodingFailed(type: "app configurations", underlying: error))
            #endif
        }
    }

    private func handleReceivedFile(fileURL: URL, metadata: [String: Any]?) {
        incomingFileHandler.handle(fileURL: fileURL, metadata: metadata)
    }

    nonisolated static func loadAppConfigurations() -> AppConfigurations {
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

final class IncomingMessageRouter {
    private let checklistManager: ChecklistViewModel
    private let galleryManager: GalleryManager
    private let authManager: AuthManager
    private let telemetryManager: TelemetryManager
    private let checklistProgressManager: ChecklistProgressManager

    init(
        checklistManager: ChecklistViewModel,
        galleryManager: GalleryManager,
        authManager: AuthManager,
        telemetryManager: TelemetryManager,
        checklistProgressManager: ChecklistProgressManager
    ) {
        self.checklistManager = checklistManager
        self.galleryManager = galleryManager
        self.authManager = authManager
        self.telemetryManager = telemetryManager
        self.checklistProgressManager = checklistProgressManager
    }

    func handle(
        message: [String: Any],
        replyHandler: (([String: Any]) -> Void)?,
        setCurrentView: (WatchViewState) -> Void,
        updateCalendarEvents: ([EventTransfer]) -> Void,
        handleLevelUpdate: (Data) -> Void
    ) {
        guard let action = message[SyncConstants.Keys.action] as? String else {
            replyHandler?([SyncConstants.Keys.status: SyncConstants.Status.noAction])
            return
        }

        switch action {
        case SyncConstants.Actions.switchToApp:
            setCurrentView(.mainMenu)
            if let appIndex = message[SyncConstants.Keys.appIndex] as? Int {
                setCurrentView(.app(appIndex))
            }

        case SyncConstants.Actions.returnToDashboard, SyncConstants.Actions.wakeUp:
            setCurrentView(.mainMenu)

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
                    authManager.updateAuthState(
                        accessToken: accessToken, refreshToken: refreshToken)
                } else {
                    authManager.clearAuthState()
                }
            }

        case SyncConstants.Actions.updateTelemetry:
            if let hasConsent = message[SyncConstants.Keys.hasConsent] as? Bool {
                telemetryManager.hasConsent = hasConsent
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
                handleLevelUpdate(data)
            }

        case SyncConstants.Actions.resetChecklistState:
            if let checklistIdString = message[SyncConstants.Keys.checklistId] as? String,
                let checklistId = UUID(uuidString: checklistIdString)
            {
                checklistProgressManager.clearProgressAndCompletion(for: checklistId)
            }

        default:
            replyHandler?([SyncConstants.Keys.status: SyncConstants.Status.unknownAction])
            return
        }

        replyHandler?([SyncConstants.Keys.status: SyncConstants.Status.success])
    }
}

extension Notification.Name {
    static let appConfigurationsUpdated = Notification.Name("appConfigurationsUpdated")
}
