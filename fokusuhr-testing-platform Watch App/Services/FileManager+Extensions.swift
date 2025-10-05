import Foundation

extension FileManager {
    
    func documentDirectory() throws -> URL {
        guard let url = urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw AppError.fileNotFound(path: "documents directory")
        }
        return url
    }
    
    func recordingFileURL() throws -> URL {
        try documentDirectory().appendingPathComponent(AppConstants.Audio.recordingFileName)
    }
    
    func removeFileIfExists(at url: URL) throws {
        if fileExists(atPath: url.path) {
            try removeItem(at: url)
        }
    }
    
    func imageURL(for imageName: String) throws -> URL {
        try documentDirectory().appendingPathComponent("\(imageName).jpg")
    }
}
