import Foundation

class TelemetryManager {
    private static let consentKey = "TelemetryConsent"
    static let shared = TelemetryManager()
    
    private init() {}
    
    func hasConsent() -> Bool {
        UserDefaults.standard.bool(forKey: Self.consentKey)
    }
    
    func updateConsent(_ consent: Bool) {
        UserDefaults.standard.set(consent, forKey: Self.consentKey)
    }
}
