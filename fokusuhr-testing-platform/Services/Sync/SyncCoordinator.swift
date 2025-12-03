import Combine
import Foundation
import WatchConnectivity

final class SyncCoordinator: ObservableObject {
    static let shared = SyncCoordinator()

    @Published var isConnected = false
    @Published var lastError: AppError?

    let transport: ConnectivityTransport
    let calendarService: CalendarSyncService
    let checklistService: ChecklistSyncService
    let levelService: LevelSyncService
    let configService: ConfigSyncService
    let authService: AuthSyncService
    let telemetryService: TelemetrySyncService
    let commandService: CommandSyncService

    private var cancellables = Set<AnyCancellable>()

    init(
        transport: ConnectivityTransport = .shared,
        calendarService: CalendarSyncService = .shared,
        checklistService: ChecklistSyncService = .shared,
        levelService: LevelSyncService = .shared,
        configService: ConfigSyncService = .shared,
        authService: AuthSyncService = .shared,
        telemetryService: TelemetrySyncService = .shared,
        commandService: CommandSyncService = .shared
    ) {
        self.transport = transport
        self.calendarService = calendarService
        self.checklistService = checklistService
        self.levelService = levelService
        self.configService = configService
        self.authService = authService
        self.telemetryService = telemetryService
        self.commandService = commandService

        setupObservers()
        loadWatchUUIDFromContext()
    }

    private func setupObservers() {
        transport.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.isConnected = isConnected
                if isConnected {
                    self?.syncAllData()
                }
            }
            .store(in: &cancellables)

        transport.$lastError
            .receive(on: DispatchQueue.main)
            .assign(to: &$lastError)

        transport.contextReceived
            .receive(on: DispatchQueue.main)
            .sink { [weak self] context in
                self?.handleIncomingContext(context)
            }
            .store(in: &cancellables)

        transport.messageReceived
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message, replyHandler in
                self?.handleIncomingMessage(message, replyHandler: replyHandler)
            }
            .store(in: &cancellables)
    }

    private func loadWatchUUIDFromContext() {
        let context = transport.getReceivedApplicationContext()
        if let watchUUID = context[SyncConstants.Keys.watchUUID] as? String {
            WatchConfig.shared.setConnectedWatchUUID(watchUUID)
        }
    }

    func syncAllData() {
        checklistService.sync()
        authService.sync()
        telemetryService.sync()
        calendarService.sync()
        levelService.sync()

        if let data = UserDefaults.standard.data(forKey: "appConfigurations"),
           let configurations = try? JSONDecoder().decode(AppConfigurations.self, from: data) {
            configService.sync(configurations)
        }
    }

    func forceReconnect() {
        transport.forceReconnect()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            if self?.isConnected == true {
                self?.loadWatchUUIDFromContext()
                self?.syncAllData()
                if self?.transport.isReachable == true {
                    self?.commandService.sendWakeUpMessage()
                }
            }
        }
    }

    private func handleIncomingContext(_ context: [String: Any]) {
        if let watchUUID = context[SyncConstants.Keys.watchUUID] as? String {
            WatchConfig.shared.setConnectedWatchUUID(watchUUID)
        }
    }

    private func handleIncomingMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)?) {
        guard let action = message[SyncConstants.Keys.action] as? String else {
            replyHandler?([SyncConstants.Keys.status: SyncConstants.Status.noAction])
            return
        }

        switch action {
        case SyncConstants.Actions.updateWatchUUID:
            if let watchUUID = message[SyncConstants.Keys.watchUUID] as? String {
                WatchConfig.shared.setConnectedWatchUUID(watchUUID)
            }

        case SyncConstants.Actions.syncLevelFromWatch:
            if let dataString = message[SyncConstants.Keys.data] as? String,
               let data = Data(base64Encoded: dataString),
               let levelData = try? JSONDecoder().decode(LevelData.self, from: data) {
                levelService.handleIncomingLevelData(levelData)
            }

        case SyncConstants.Actions.requestLevelData:
            levelService.sync()

        default:
            #if DEBUG
                print("📱 iOS: Unknown action: \(action)")
            #endif
        }

        replyHandler?([SyncConstants.Keys.status: SyncConstants.Status.success])
    }
}

