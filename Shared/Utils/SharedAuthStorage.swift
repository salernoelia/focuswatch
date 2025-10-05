import Foundation

struct SharedAuthStorage {
    private static let suiteName = "group.com.fokusuhr.testing"
    private static let sessionKey = "supabase.session"
    
    static var shared: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }
    
    static func saveSession(_ sessionData: Data) {
        shared?.set(sessionData, forKey: sessionKey)
    }
    
    static func loadSession() -> Data? {
        shared?.data(forKey: sessionKey)
    }
    
    static func clearSession() {
        shared?.removeObject(forKey: sessionKey)
    }
}
