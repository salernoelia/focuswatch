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

    let transport: ConnectivityTransport

    private let checklistManager = ChecklistViewModel.shared
    private let galleryManager = GalleryManager.shared
    private let calendarManager = CalendarViewModel.shared
    private let authManager = AuthManager.shared

    private var cancellables = Set<AnyCancellable>()

    init(transport: ConnectivityTransport = .shared) {
        self.transport = transport
        setupObservers()
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
    }

    func forceReconnect() {
        transport.forceReconnect()
    }

    func checkForCalendarUpdates() {
        transport.loadLatestApplicationContext()
    }

    private func handleApplicationContext(_ context: [String: Any]) {
        if let calendarDataBytes = context[SyncConstants.Keys.calendarData] as? Data,
           let events = try? JSONDecoder().decode([EventTransfer].self, from: calendarDataBytes) {
            calendarManager.updateEvents(events)
        } else if let calendarDataString = context[SyncConstants.Keys.calendarData] as? String,
                  let data = Data(base64Encoded: calendarDataString),
                  let events = try? JSONDecoder().decode([EventTransfer].self, from: data) {
            calendarManager.updateEvents(events)
        }

        if let checklistDataBytes = context[SyncConstants.Keys.checklistData] as? Data {
            let forceOverwrite = context[SyncConstants.Keys.forceOverwrite] as? Bool ?? false
            checklistManager.updateChecklistData(from: checklistDataBytes, forceOverwrite: forceOverwrite)

            if let imageData = context[SyncConstants.Keys.checklistImageData] as? [String: String] {
                galleryManager.saveGalleryImages(imageData)
            }
        } else if let checklistDataString = context[SyncConstants.Keys.checklistData] as? String,
                  let data = Data(base64Encoded: checklistDataString) {
            let forceOverwrite = context[SyncConstants.Keys.forceOverwrite] as? Bool ?? false
            checklistManager.updateChecklistData(from: data, forceOverwrite: forceOverwrite)

            if let imageData = context[SyncConstants.Keys.checklistImageData] as? [String: String] {
                galleryManager.saveGalleryImages(imageData)
            }
        }

        if let levelDataBytes = context[SyncConstants.Keys.levelData] as? Data {
            handleLevelUpdate(data: levelDataBytes)
        } else if let levelDataString = context[SyncConstants.Keys.levelData] as? String,
                  let data = Data(base64Encoded: levelDataString) {
            handleLevelUpdate(data: data)
        }

        if let configDataBytes = context[SyncConstants.Keys.appConfigurations] as? Data {
            handleConfigurationsUpdate(data: configDataBytes)
        } else if let configDataString = context[SyncConstants.Keys.appConfigurations] as? String,
                  let data = Data(base64Encoded: configDataString) {
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
               let data = Data(base64Encoded: dataString) {
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
                   let refreshToken = message[SyncConstants.Keys.refreshToken] as? String {
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
               let events = try? JSONDecoder().decode([EventTransfer].self, from: data) {
                calendarManager.updateEvents(events)
            }

        case SyncConstants.Actions.updateLevel:
            if let dataString = message[SyncConstants.Keys.data] as? String,
               let data = Data(base64Encoded: dataString) {
                handleLevelUpdate(data: data)
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
               let data = Data(base64Encoded: dataString) {
                let forceOverwrite = userInfo[SyncConstants.Keys.forceOverwrite] as? Bool ?? false
                checklistManager.updateChecklistData(from: data, forceOverwrite: forceOverwrite)
            }
            if let imageData = userInfo[SyncConstants.Keys.imageData] as? [String: String] {
                galleryManager.saveGalleryImages(imageData)
            }

        case SyncConstants.Actions.updateTelemetry:
            if let hasConsent = userInfo[SyncConstants.Keys.hasConsent] as? Bool {
                TelemetryManager.shared.hasConsent = hasConsent
            }

        case SyncConstants.Actions.updateLevel:
            if let dataString = userInfo[SyncConstants.Keys.data] as? String,
               let data = Data(base64Encoded: dataString) {
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
               let data = Data(base64Encoded: dataString) {
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
               let data = Data(base64Encoded: dataString) {
                handleLevelUpdate(data: data)
            }

        default:
            break
        }
    }

    private func handleLevelUpdate(data: Data) {
        do {
            let levelData = try JSONDecoder().decode(LevelData.self, from: data)
            saveLevelMilestones(levelData.milestones)
            NotificationCenter.default.post(name: NSNotification.Name("LevelMilestonesUpdated"), object: nil)
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
                    SyncConstants.Keys.timestamp: Date().timeIntervalSince1970
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
            SyncConstants.Keys.timestamp: Date().timeIntervalSince1970
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

