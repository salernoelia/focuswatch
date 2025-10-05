import Foundation

enum ChecklistStorage {
    private static let storageKey = AppConstants.StorageKeys.checklistData
    
    static func save(_ checklistData: ChecklistData) {
        do {
            let data = try JSONEncoder().encode(checklistData)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            #if DEBUG
            ErrorLogger.log(AppError.encodingFailed(type: "ChecklistData", underlying: error))
            #endif
        }
    }
    
    static func load() -> ChecklistData {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return ChecklistData.default
        }
        
        do {
            return try JSONDecoder().decode(ChecklistData.self, from: data)
        } catch {
            #if DEBUG
            ErrorLogger.log(AppError.decodingFailed(type: "ChecklistData", underlying: error))
            #endif
            return ChecklistData.default
        }
    }
    
    static func saveGalleryImages(_ imageData: [String: String]) {
        do {
            let documentsPath = try FileManager.default.documentDirectory()
            
            for (imageName, base64String) in imageData {
                guard let data = Data(base64Encoded: base64String) else { continue }
                let imageURL = documentsPath.appendingPathComponent("\(imageName).jpg")
                try data.write(to: imageURL)
            }
        } catch {
            #if DEBUG
            ErrorLogger.log(AppError.fileOperationFailed(operation: "save gallery images", underlying: error))
            #endif
        }
    }
    
    static func clearGalleryImages() {
        do {
            let documentsPath = try FileManager.default.documentDirectory()
            let contents = try FileManager.default.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: nil)
            
            for fileURL in contents where fileURL.pathExtension == "jpg" {
                try? FileManager.default.removeItem(at: fileURL)
            }
        } catch {
            #if DEBUG
            ErrorLogger.log(AppError.fileOperationFailed(operation: "clear gallery images", underlying: error))
            #endif
        }
    }
}
