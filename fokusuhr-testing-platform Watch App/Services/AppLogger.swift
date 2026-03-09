import Foundation
import Supabase

class AppLogger: NSObject, ObservableObject {
    private var authManager = AuthManager.shared
    
    static let shared = AppLogger()
    
    private override init() {
        super.init()
    }
    
    private var deviceId: UUID? {
      let sharedDefaults = UserDefaults(suiteName: "group.net.com.fokusuhr")
      let uuidString = sharedDefaults?.string(forKey: "deviceUUID")
      #if DEBUG
        print(" Widget reading deviceUUID: \(uuidString ?? "nil")")
      #endif
      return uuidString.flatMap { UUID(uuidString: $0) }
    }
    
    /// Retrieves the app version from the bundle info dictionary
    /// Handles both regular app bundles and app extensions
    private var appVersion: String {
        var bundle = Bundle.main
        
        // Handle app extensions - navigate to parent app bundle
        if bundle.bundleURL.pathExtension == "appex" {
            let url = bundle.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
            if let appBundle = Bundle(url: url) {
                bundle = appBundle
            }
        }
        
        return bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    func logEvent(appName: String, appId: Int64? = nil, data: [String: Any]? = nil) async {

 
        
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
            id: nil,
            watchId: (self.deviceId ?? UUID(uuidString: "3453caf6-4404-4e1a-835b-afc64fc82178"))!
        )
        
        do {
            try await supabase
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
    
    /// Safely logs view lifecycle events (onAppear/onDisappear)
    /// This method is designed to never block or crash the app
    /// It checks telemetry consent and handles all errors gracefully
    func logViewLifecycle(appName: String, event: String) {
        // Wrap everything in a do-catch to ensure nothing can crash
        do {
            // Check telemetry consent first - fail silently if no consent
            guard TelemetryManager.shared.hasConsent else {
                return
            }
            
            // Dispatch async in background - never block the main thread
            Task.detached(priority: .utility) { [weak self] in
                guard let self = self else { return }
                let data: [String: Any] = [
                    "event_type": "view_lifecycle",
                    "lifecycle_event": event,
                    "app_version": self.appVersion
                ]
                await self.logEvent(appName: appName, appId: self.versionToAppId(self.appVersion), data: data)
            }
        } 
    }
    
    /// Converts app version string to an Int64 for app_id column
    /// Handles versions like "1.1.8" by converting to numeric format
    private func versionToAppId(_ version: String) -> Int64? {
        // Remove any non-numeric characters except dots
        let cleaned = version.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        
        // Split by dots and take first 3 parts (major.minor.patch)
        let parts = cleaned.split(separator: ".").compactMap { Int64($0) }
        
        guard parts.count >= 1 else { return nil }
        
        // Convert to Int64: major * 10000 + minor * 100 + patch

        let major = parts[0]
        let minor = parts.count > 1 ? parts[1] : 0
        let patch = parts.count > 2 ? parts[2] : 0
        
        return major * 10000 + minor * 100 + patch
    }
}

