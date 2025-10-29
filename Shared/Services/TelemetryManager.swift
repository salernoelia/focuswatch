import Foundation
#if os(iOS)
import WatchConnectivity
#endif

class TelemetryManager: ObservableObject {
    @Published var hasConsent: Bool {
        didSet {
            updateConsent(hasConsent)
            #if os(iOS)
            syncConsentToWatch()
            #endif
        }
    }
    private static let consentKey = "TelemetryConsent"
    static let shared = TelemetryManager()
    
    private init() {
        hasConsent = UserDefaults.standard.bool(forKey: Self.consentKey)
    }
    
    private func updateConsent(_ consent: Bool) {
        UserDefaults.standard.set(consent, forKey: Self.consentKey)
    }
    
    #if os(iOS)
    private func syncConsentToWatch() {
        guard WCSession.isSupported() else { return }
        
        let userInfo: [String: Any] = [
            "action": "updateTelemetry",
            "hasConsent": hasConsent
        ]
        
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(userInfo, replyHandler: { response in
                #if DEBUG
                print("Telemetry consent synced to watch: \(response)")
                #endif
            }) { error in
                #if DEBUG
                print("Failed to sync telemetry consent to watch: \(error.localizedDescription)")
                #endif
                WCSession.default.transferUserInfo(userInfo)
            }
        } else {
            WCSession.default.transferUserInfo(userInfo)
            #if DEBUG
            print("Watch not reachable, queued telemetry sync for background transfer")
            #endif
        }
    }
    #endif
}
