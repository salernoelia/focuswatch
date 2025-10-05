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
        guard WCSession.default.isReachable else {
            #if DEBUG
            print("Watch not reachable for telemetry sync")
            #endif
            return
        }
        
        let message: [String: Any] = [
            "action": "updateTelemetry",
            "hasConsent": hasConsent
        ]
        
        WCSession.default.sendMessage(message, replyHandler: { response in
            #if DEBUG
            print("Telemetry consent synced to watch: \(response)")
            #endif
        }) { error in
            #if DEBUG
            print("Failed to sync telemetry consent to watch: \(error.localizedDescription)")
            #endif
        }
    }
    #endif
}
