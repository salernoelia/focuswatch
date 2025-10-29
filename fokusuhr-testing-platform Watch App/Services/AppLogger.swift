import Foundation
import Supabase

class AppLogger: NSObject, ObservableObject {
    // Use a dedicated anonymous client for logging that doesn't require authentication
    private let client: SupabaseClient
    
    static let shared = AppLogger()
    
    private override init() {
        // Create a client that uses only the anon key, ensuring logging works without authentication
        self.client = SupabaseClient(
            supabaseURL: SupabaseConfig.url,
            supabaseKey: SupabaseConfig.anonKey
        )
        super.init()
    }
    
    func logEvent(appName: String, watchId: UUID, data: [String: Any]? = nil) async {
        
        let logEntry = PublicSchema.AppLogsInsert(
            appId: nil,
            appName: appName,
            createdAt: nil,
            data: data.flatMap { dict in
                guard let jsonData = try? JSONSerialization.data(withJSONObject: dict),
                      let anyJSON = try? JSONDecoder().decode(AnyJSON.self, from: jsonData) else {
                    return nil
                }
                return anyJSON
            },
            id: nil,
            watchId: watchId
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
    
    func logSimpleEvent(appName: String, watchId: UUID, eventType: String, details: String? = nil) async {
        var data: [String: Any] = ["event_type": eventType]
        if let details = details {
            data["details"] = details
        }
        await logEvent(appName: appName, watchId: watchId, data: data)
    }
}

