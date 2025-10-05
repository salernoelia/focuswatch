import Foundation
import Supabase

class AppLogger: NSObject, ObservableObject {
    private var authManager = AuthManager.shared
    
    static let shared = AppLogger()
    
    private override init() {
        super.init()
    }
    
    func logEvent(appName: String, appId: Int64? = nil, data: [String: Any]? = nil) async {
        guard authManager.isLoggedIn else {
            #if DEBUG
            print("Cannot log event: Not authenticated")
            #endif
            return
        }
        
        guard let client = authManager.getClient() else {
            #if DEBUG
            print("Cannot log event: No client available")
            #endif
            return
        }
        
        let logEntry = PublicSchema.AppLogsInsert(
            appId: appId,
            appName: appName,
            createdAt: nil,
            data: data.flatMap { dict in
                guard let jsonData = try? JSONSerialization.data(withJSONObject: dict),
                      let anyJSON = try? JSONDecoder().decode(AnyJSON.self, from: jsonData) else {
                    return nil
                }
                return anyJSON
            },
            id: nil
        )
        
        do {
            try await client
                .from("app_logs")
                .insert(logEntry)
                .execute()
            
            #if DEBUG
            print("Successfully logged event for app: \(appName)")
            #endif
        } catch {
            #if DEBUG
            print("Failed to log event: \(error.localizedDescription)")
            #endif
        }
    }
    
    func logSimpleEvent(appName: String, eventType: String, details: String? = nil) async {
        var data: [String: Any] = ["event_type": eventType]
        if let details = details {
            data["details"] = details
        }
        await logEvent(appName: appName, data: data)
    }
}

