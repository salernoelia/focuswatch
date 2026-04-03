import Foundation

@MainActor
final class IncomingContextHandler {
    private let checklistManager: ChecklistViewModel
    private let galleryManager: GalleryManager

    init(
        checklistManager: ChecklistViewModel,
        galleryManager: GalleryManager
    ) {
        self.checklistManager = checklistManager
        self.galleryManager = galleryManager
    }

    @discardableResult
    func handle(
        _ context: [String: Any],
        updateCalendarEvents: ([EventTransfer]) -> Void,
        handleLevelUpdate: (Data) -> Void,
        handleConfigurationsUpdate: (Data) -> Void,
        handleLegacyAction: (String, [String: Any]) -> Void
    ) -> Bool {
        #if DEBUG
            ErrorLogger.log("Watch: Received applicationContext")
            ErrorLogger.log("Watch: Context keys: \(context.keys.joined(separator: ", "))")
        #endif

        if let calendarDataBytes = context[SyncConstants.Keys.calendarData] as? Data,
            let events = try? JSONDecoder().decode([EventTransfer].self, from: calendarDataBytes)
        {
            updateCalendarEvents(events)
        } else if let calendarDataString = context[SyncConstants.Keys.calendarData] as? String,
            let data = Data(base64Encoded: calendarDataString),
            let events = try? JSONDecoder().decode([EventTransfer].self, from: data)
        {
            updateCalendarEvents(events)
        }

        var checklistUpdated = false

        if let checklistDataBytes = context[SyncConstants.Keys.checklistData] as? Data {
            let forceOverwrite = context[SyncConstants.Keys.forceOverwrite] as? Bool ?? false

            #if DEBUG
                ErrorLogger.log(
                    "Watch: Processing checklist data (forceOverwrite: \(forceOverwrite), size: \(checklistDataBytes.count) bytes)"
                )
                if let decodedData = try? JSONDecoder().decode(
                    ChecklistData.self, from: checklistDataBytes)
                {
                    ErrorLogger.log(
                        "Watch: Decoded \(decodedData.checklists.count) checklists from context")
                    for (index, checklist) in decodedData.checklists.enumerated() {
                        ErrorLogger.log(
                            "Watch:   [\(index)] \(checklist.name) - \(checklist.items.count) items"
                        )
                    }
                }
            #endif

            if let imageData = context[SyncConstants.Keys.checklistImageData] as? [String: String],
                !imageData.isEmpty
            {
                #if DEBUG
                    ErrorLogger.log("Watch: Saving \(imageData.count) gallery images from context")
                #endif
                galleryManager.saveGalleryImages(imageData)
            } else {
                #if DEBUG
                    ErrorLogger.log("Watch: No images in context payload")
                #endif
            }

            checklistManager.updateChecklistData(
                from: checklistDataBytes, forceOverwrite: forceOverwrite)
            checklistUpdated = true
        } else if let checklistDataString = context[SyncConstants.Keys.checklistData] as? String,
            let data = Data(base64Encoded: checklistDataString)
        {
            let forceOverwrite = context[SyncConstants.Keys.forceOverwrite] as? Bool ?? false

            #if DEBUG
                ErrorLogger.log(
                    "Watch: Processing base64 checklist data (forceOverwrite: \(forceOverwrite))")
            #endif

            if let imageData = context[SyncConstants.Keys.checklistImageData] as? [String: String],
                !imageData.isEmpty
            {
                #if DEBUG
                    ErrorLogger.log(
                        "Watch: Saving \(imageData.count) gallery images from base64 context")
                #endif
                galleryManager.saveGalleryImages(imageData)
            } else {
                #if DEBUG
                    ErrorLogger.log("Watch: No images in base64 context payload")
                #endif
            }

            checklistManager.updateChecklistData(from: data, forceOverwrite: forceOverwrite)
            checklistUpdated = true
        }

        if let levelDataBytes = context[SyncConstants.Keys.levelData] as? Data {
            handleLevelUpdate(levelDataBytes)
        } else if let levelDataString = context[SyncConstants.Keys.levelData] as? String,
            let data = Data(base64Encoded: levelDataString)
        {
            handleLevelUpdate(data)
        }

        if let configDataBytes = context[SyncConstants.Keys.appConfigurations] as? Data {
            handleConfigurationsUpdate(configDataBytes)
        } else if let configDataString = context[SyncConstants.Keys.appConfigurations] as? String,
            let data = Data(base64Encoded: configDataString)
        {
            handleConfigurationsUpdate(data)
        }

        if let action = context[SyncConstants.Keys.action] as? String {
            handleLegacyAction(action, context)
        }

        return checklistUpdated
    }
}
