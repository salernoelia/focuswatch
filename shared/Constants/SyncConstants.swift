import Foundation

enum SyncMessageType: String, Codable {
    case calendar
    case checklist
    case level
    case config
    case auth
    case telemetry
    case command
    case watchUUID
}

enum SyncConstants {

    enum Keys {
        static let calendarData = "calendarData"
        static let checklistData = "checklistData"
        static let checklistImageData = "checklistImageData"
        static let levelData = "levelData"
        static let appConfigurations = "appConfigurations"
        static let timestamp = "timestamp"
        static let forceOverwrite = "forceOverwrite"
        static let action = "action"
        static let data = "data"
        static let imageData = "imageData"
        static let watchUUID = "watchUUID"
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
        static let isLoggedIn = "isLoggedIn"
        static let hasConsent = "hasConsent"
        static let appIndex = "appIndex"
        static let status = "status"
        static let imageName = "imageName"
        static let imageHash = "imageHash"
        static let syncType = "syncType"
        static let syncId = "syncId"
        static let receivedImages = "receivedImages"
        static let missingImages = "missingImages"
        static let requiredImages = "requiredImages"
        static let syncStatus = "syncStatus"
        static let checklistId = "checklistId"
        static let tileOrder = "tileOrder"
    }

    enum Actions {
        static let updateChecklist = "updateChecklist"
        static let updateAuth = "updateAuth"
        static let updateTelemetry = "updateTelemetry"
        static let updateCalendar = "updateCalendar"
        static let updateLevel = "updateLevel"
        static let updateWatchUUID = "updateWatchUUID"
        static let syncLevelFromWatch = "syncLevelFromWatch"
        static let requestLevelData = "requestLevelData"
        static let switchToApp = "switchToApp"
        static let returnToDashboard = "returnToDashboard"
        static let wakeUp = "wakeUp"
        static let acknowledgeImages = "acknowledgeImages"
        static let requestMissingImages = "requestMissingImages"
        static let reportSyncStatus = "reportSyncStatus"
        static let forceSync = "forceSync"
        static let resetChecklistState = "resetChecklistState"
    }

    enum Status {
        static let success = "success"
        static let unknownAction = "unknown_action"
        static let noAction = "no_action"
        static let pending = "pending"
        static let complete = "complete"
        static let partial = "partial"
        static let failed = "failed"
    }

    enum Timing {
        static let retryDelay: TimeInterval = 5.0
        static let maxRetries = 5
        static let syncTimeout: TimeInterval = 30.0
        static let verificationInterval: TimeInterval = 10.0
    }
}

