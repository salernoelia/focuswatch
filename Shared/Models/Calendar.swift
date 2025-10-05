
import Foundation

enum RepeatRule: String, CaseIterable, Identifiable, Codable {
    case none, daily, weekly, weekdays, custom
    var id: String { rawValue }
}

enum ActivityType: String, CaseIterable, Identifiable, Codable {
    case homework, sports, music, other
    var id: String { rawValue }
}
