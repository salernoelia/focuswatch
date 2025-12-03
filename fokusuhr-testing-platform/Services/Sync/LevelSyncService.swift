import Combine
import Foundation
import WatchConnectivity

final class LevelSyncService: ObservableObject {
    static let shared = LevelSyncService()

    @Published var lastError: AppError?

    private let transport: ConnectivityTransport
    private var isSyncing = false

    init(transport: ConnectivityTransport = .shared) {
        self.transport = transport
    }

    func sync() {
        guard WCSession.default.activationState == .activated else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.sync()
            }
            return
        }

        guard !isSyncing else { return }

        isSyncing = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            do {
                let levelData = self.loadLevelData()
                let data = try JSONEncoder().encode(levelData)

                let context: [String: Any] = [
                    SyncConstants.Keys.levelData: data,
                    SyncConstants.Keys.timestamp: Date().timeIntervalSince1970
                ]

                try self.transport.updateApplicationContext(context)

                #if DEBUG
                    DispatchQueue.main.async {
                        print("iOS: Level synced - Level \(levelData.currentLevel)")
                    }
                #endif

                DispatchQueue.main.async {
                    self.isSyncing = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isSyncing = false
                    self.lastError = AppError.encodingFailed(type: "level data", underlying: error)
                    #if DEBUG
                        ErrorLogger.log(AppError.encodingFailed(type: "level data", underlying: error))
                    #endif
                }
            }
        }
    }

    func saveLevelData(_ levelData: LevelData) {
        do {
            let data = try JSONEncoder().encode(levelData)
            UserDefaults.standard.set(data, forKey: "levelData")
        } catch {
            #if DEBUG
                ErrorLogger.log(AppError.encodingFailed(type: "level data", underlying: error))
            #endif
            lastError = AppError.encodingFailed(type: "level data", underlying: error)
        }
    }

    func loadLevelData() -> LevelData {
        guard let data = UserDefaults.standard.data(forKey: "levelData") else {
            return LevelData.default
        }

        do {
            return try JSONDecoder().decode(LevelData.self, from: data)
        } catch {
            #if DEBUG
                ErrorLogger.log(AppError.decodingFailed(type: "level data", underlying: error))
            #endif
            return LevelData.default
        }
    }

    func handleIncomingLevelData(_ levelData: LevelData) {
        var existingData = loadLevelData()
        existingData.currentLevel = levelData.currentLevel
        existingData.currentXP = levelData.currentXP
        existingData.totalXP = levelData.totalXP
        existingData.lastUpdated = levelData.lastUpdated

        saveLevelData(existingData)

        NotificationCenter.default.post(
            name: NSNotification.Name("LevelDataUpdated"),
            object: nil,
            userInfo: ["levelData": existingData]
        )
    }
}

