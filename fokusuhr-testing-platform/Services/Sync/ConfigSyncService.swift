import Foundation
import WatchConnectivity

final class ConfigSyncService {
    static let shared = ConfigSyncService()

    private let transport: ConnectivityTransport

    init(transport: ConnectivityTransport = .shared) {
        self.transport = transport
    }

    func sync(_ configurations: AppConfigurations) {
        guard WCSession.default.activationState == .activated else { return }

        do {
            let data = try JSONEncoder().encode(configurations)
            let context: [String: Any] = [
                SyncConstants.Keys.appConfigurations: data,
                SyncConstants.Keys.timestamp: Date().timeIntervalSince1970
            ]

            try transport.updateApplicationContext(context)

            #if DEBUG
                print("iOS: App configurations synced")
            #endif
        } catch {
            #if DEBUG
                ErrorLogger.log(AppError.encodingFailed(type: "app configurations", underlying: error))
            #endif
        }
    }

    func loadFromUserDefaults() -> AppConfigurations {
        guard let data = UserDefaults.standard.data(forKey: "appConfigurations") else {
            return AppConfigurations.default
        }

        do {
            return try JSONDecoder().decode(AppConfigurations.self, from: data)
        } catch {
            #if DEBUG
                ErrorLogger.log(AppError.decodingFailed(type: "app configurations", underlying: error))
            #endif
            return AppConfigurations.default
        }
    }

    func saveToUserDefaults(_ configurations: AppConfigurations) {
        do {
            let data = try JSONEncoder().encode(configurations)
            UserDefaults.standard.set(data, forKey: "appConfigurations")
        } catch {
            #if DEBUG
                ErrorLogger.log(AppError.encodingFailed(type: "app configurations", underlying: error))
            #endif
        }
    }
}

