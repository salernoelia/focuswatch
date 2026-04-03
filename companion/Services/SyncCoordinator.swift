import Combine
import Foundation
import WatchConnectivity

final class SyncCoordinator: ObservableObject {
    static let shared = SyncCoordinator(transport: ConnectivityTransportAdapter())

    @Published var isConnected = false
    @Published var lastError: AppError?
    @Published private(set) var syncStatus: String = SyncConstants.Status.pending

    let transport: SyncTransportProtocol
    let calendarService: CalendarSyncService
    let checklistService: ChecklistSyncService
    let levelService: LevelSyncService
    let configService: ConfigSyncService
    let authService: AuthSyncService
    let telemetryService: TelemetrySyncService
    let commandService: CommandSyncService
    let imageSyncService: ImageSyncService

    private var cancellables = Set<AnyCancellable>()

    init(
        transport: SyncTransportProtocol = ConnectivityTransportAdapter(),
        calendarService: CalendarSyncService = .shared,
        checklistService: ChecklistSyncService = .shared,
        levelService: LevelSyncService = .shared,
        configService: ConfigSyncService = .shared,
        authService: AuthSyncService = .shared,
        telemetryService: TelemetrySyncService = .shared,
        commandService: CommandSyncService = .shared,
        imageSyncService: ImageSyncService = .shared
    ) {
        self.transport = transport
        self.calendarService = calendarService
        self.checklistService = checklistService
        self.levelService = levelService
        self.configService = configService
        self.authService = authService
        self.telemetryService = telemetryService
        self.commandService = commandService
        self.imageSyncService = imageSyncService

        setupObservers()
        loadWatchUUIDFromContext()
    }

    private func setupObservers() {
        transport.isConnectedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.isConnected = isConnected
                if isConnected {
                    self?.syncAllData()
                }
            }
            .store(in: &cancellables)

        transport.lastErrorPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$lastError)

        transport.contextReceivedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] context in
                self?.handleIncomingContext(context)
            }
            .store(in: &cancellables)

        transport.messageReceivedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message, replyHandler in
                self?.handleIncomingMessage(message, replyHandler: replyHandler)
            }
            .store(in: &cancellables)

        imageSyncService.$syncProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                if progress >= 1.0 {
                    self?.syncStatus = SyncConstants.Status.complete
                } else if progress > 0 {
                    self?.syncStatus = SyncConstants.Status.partial
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSNotification.Name("AllImagesAcknowledged"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.syncStatus = SyncConstants.Status.complete
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
        checklistService.forceSync()
        authService.sync()
        telemetryService.sync()
        calendarService.sync()
        levelService.sync()

        if let data = UserDefaults.standard.data(forKey: "appConfigurations"),
            let configurations = try? JSONDecoder().decode(AppConfigurations.self, from: data)
        {
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

    private func handleIncomingMessage(
        _ message: [String: Any],
        replyHandler: (([String: Any]) -> Void)?
    ) {
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
                let levelData = try? JSONDecoder().decode(LevelData.self, from: data)
            {
                levelService.handleIncomingLevelData(levelData)
            }

        case SyncConstants.Actions.requestLevelData:
            levelService.sync()

        case SyncConstants.Actions.forceSync:
            #if DEBUG
                print("iOS SyncCoordinator: Received forceSync request")
            #endif
            syncStatus = SyncConstants.Status.pending
            checklistService.forceSyncWithImages()

        case SyncConstants.Actions.reportSyncStatus:
            if let status = message[SyncConstants.Keys.syncStatus] as? String {
                #if DEBUG
                    print("iOS SyncCoordinator: Watch reported sync status: \(status)")
                #endif
                if status == SyncConstants.Status.complete {
                    syncStatus = SyncConstants.Status.complete
                }
            }

        default:
            #if DEBUG
                print("iOS SyncCoordinator: Unknown action: \(action)")
            #endif
        }

        replyHandler?([SyncConstants.Keys.status: SyncConstants.Status.success])
    }

    func forceSyncChecklists() {
        syncStatus = SyncConstants.Status.pending
        checklistService.forceSyncWithImages()
    }
}
