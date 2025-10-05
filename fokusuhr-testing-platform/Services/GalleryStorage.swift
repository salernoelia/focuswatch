import SwiftUI
import PhotosUI
import SwiftData

@MainActor
class GalleryStorage: ObservableObject {
    private let modelContext: ModelContext
    
    @Published var items: [GalleryItemModel] = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchItems()
    }
    
    private func fetchItems() {
        let descriptor = FetchDescriptor<GalleryItemModel>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            items = try modelContext.fetch(descriptor)
        } catch {
            #if DEBUG
            ErrorLogger.log(.databaseQueryFailed(operation: "fetch gallery items", underlying: error))
            #endif
            items = []
        }
    }
    
    func addItem(image: UIImage, label: String) {
        let imageName = "\(UUID().uuidString).jpg"
        
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            #if DEBUG
            ErrorLogger.log(.fileNotFound(path: "documents directory"))
            #endif
            return
        }
        
        let url = documentsURL.appendingPathComponent(imageName)
        
        let resizedImage = resizeImage(image, targetSize: AppConstants.Image.thumbnailSize)
        
        guard let data = resizedImage.jpegData(compressionQuality: AppConstants.Image.compressionQuality) else {
            #if DEBUG
            ErrorLogger.log(.encodingFailed(type: "image", underlying: NSError(domain: "GalleryStorage", code: -1, userInfo: nil)))
            #endif
            return
        }
        
        do {
            try data.write(to: url)
            let item = GalleryItemModel(imagePath: imageName, label: label)
            modelContext.insert(item)
            saveChanges()
        } catch {
            #if DEBUG
            ErrorLogger.log(.fileOperationFailed(operation: "save image", underlying: error))
            #endif
        }
    }
    
    func deleteItem(_ item: GalleryItemModel) {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            #if DEBUG
            ErrorLogger.log(.fileNotFound(path: "documents directory"))
            #endif
            return
        }
        
        let url = documentsURL.appendingPathComponent(item.imagePath)
        
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                #if DEBUG
                ErrorLogger.log(.fileOperationFailed(operation: "delete image", underlying: error))
                #endif
            }
        }
        
        modelContext.delete(item)
        saveChanges()
    }
    
    func deleteItems(at offsets: IndexSet) {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            #if DEBUG
            ErrorLogger.log(.fileNotFound(path: "documents directory"))
            #endif
            return
        }
        
        for index in offsets {
            let item = items[index]
            let url = documentsURL.appendingPathComponent(item.imagePath)
            
            if FileManager.default.fileExists(atPath: url.path) {
                do {
                    try FileManager.default.removeItem(at: url)
                } catch {
                    #if DEBUG
                    ErrorLogger.log(.fileOperationFailed(operation: "delete image", underlying: error))
                    #endif
                }
            }
            modelContext.delete(item)
        }
        
        saveChanges()
    }
    
    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        let newSize = widthRatio > heightRatio ?
            CGSize(width: size.width * heightRatio, height: targetSize.height) :
            CGSize(width: targetSize.width, height: size.height * widthRatio)
        
        let rect = CGRect(origin: .zero, size: newSize)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, AppConstants.Image.renderingScale)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
    
    private func saveChanges() {
        do {
            try modelContext.save()
            fetchItems()
        } catch {
            #if DEBUG
            ErrorLogger.log(.databaseQueryFailed(operation: "save gallery", underlying: error))
            #endif
        }
    }

    func updateItemLabel(_ item: GalleryItemModel, newLabel: String) {
        item.label = newLabel
        saveChanges()
    }
}
