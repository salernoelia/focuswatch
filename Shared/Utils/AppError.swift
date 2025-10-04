
import Foundation

enum AppError: LocalizedError {
    
    // MARK: - Authentication Errors
    case authenticationFailed(reason: String)
    case noActiveSession
    case invalidCredentials
    
    // MARK: - Network Errors
    case networkUnavailable
    case requestFailed(statusCode: Int, message: String)
    case invalidResponse
    case serverError(underlying: Error)
    
    // MARK: - Data Errors
    case decodingFailed(type: String, underlying: Error)
    case encodingFailed(type: String, underlying: Error)
    case invalidData(reason: String)
    case missingRequiredField(field: String)
    
    // MARK: - Database Errors
    case databaseQueryFailed(operation: String, underlying: Error)
    case recordNotFound(type: String, id: String)
    case duplicateRecord(type: String)
    
    // MARK: - File System Errors
    case fileNotFound(path: String)
    case fileOperationFailed(operation: String, underlying: Error)
    case insufficientStorage
    
    // MARK: - Watch Connectivity Errors
    case watchNotSupported
    case watchNotConnected
    case watchNotReachable
    case watchMessageFailed(underlying: Error)
    case watchSessionInactive
    
    // MARK: - Audio Errors
    case microphoneAccessDenied
    case recordingFailed(reason: String)
    case playbackFailed(reason: String)
    case audioSessionError(underlying: Error)
    
    // MARK: - Validation Errors
    case invalidInput(field: String, reason: String)
    case textTooShort(field: String, minLength: Int)
    case textTooLong(field: String, maxLength: Int)
    case emptyField(field: String)
    
    // MARK: - General Errors
    case unknown(underlying: Error)
    case operationCancelled
    case timeout
    
    
    var errorDescription: String? {
        switch self {
        // Authentication
        case .authenticationFailed(let reason):
            return "Authentication failed: \(reason)"
        case .noActiveSession:
            return "No active user session. Please log in."
        case .invalidCredentials:
            return "Invalid username or password."
            
        // Network
        case .networkUnavailable:
            return "Network connection unavailable."
        case .requestFailed(let statusCode, let message):
            return "Request failed (HTTP \(statusCode)): \(message)"
        case .invalidResponse:
            return "Received invalid response from server."
        case .serverError(let error):
            return "Server error: \(error.localizedDescription)"
            
        // Data
        case .decodingFailed(let type, let error):
            return "Failed to decode \(type): \(error.localizedDescription)"
        case .encodingFailed(let type, let error):
            return "Failed to encode \(type): \(error.localizedDescription)"
        case .invalidData(let reason):
            return "Invalid data: \(reason)"
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
            
        // Database
        case .databaseQueryFailed(let operation, let error):
            return "Database \(operation) failed: \(error.localizedDescription)"
        case .recordNotFound(let type, let id):
            return "\(type) not found with ID: \(id)"
        case .duplicateRecord(let type):
            return "Duplicate \(type) already exists."
            
        // File System
        case .fileNotFound(let path):
            return "File not found at: \(path)"
        case .fileOperationFailed(let operation, let error):
            return "File \(operation) failed: \(error.localizedDescription)"
        case .insufficientStorage:
            return "Insufficient storage space."
            
        // Watch Connectivity
        case .watchNotSupported:
            return "Apple Watch connectivity is not supported on this device."
        case .watchNotConnected:
            return "Apple Watch is not connected."
        case .watchNotReachable:
            return "Apple Watch is not reachable. Make sure it's nearby and unlocked."
        case .watchMessageFailed(let error):
            return "Failed to communicate with Apple Watch: \(error.localizedDescription)"
        case .watchSessionInactive:
            return "Watch connectivity session is inactive."
            
        // Audio
        case .microphoneAccessDenied:
            return "Microphone access denied. Please enable in Settings."
        case .recordingFailed(let reason):
            return "Recording failed: \(reason)"
        case .playbackFailed(let reason):
            return "Playback failed: \(reason)"
        case .audioSessionError(let error):
            return "Audio session error: \(error.localizedDescription)"
            
        // Validation
        case .invalidInput(let field, let reason):
            return "Invalid \(field): \(reason)"
        case .textTooShort(let field, let minLength):
            return "\(field) must be at least \(minLength) characters."
        case .textTooLong(let field, let maxLength):
            return "\(field) must be no more than \(maxLength) characters."
        case .emptyField(let field):
            return "\(field) cannot be empty."
            
        // General
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        case .operationCancelled:
            return "Operation was cancelled."
        case .timeout:
            return "Operation timed out."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .authenticationFailed, .invalidCredentials:
            return "Please check your credentials and try again."
        case .noActiveSession:
            return "Please log in to continue."
        case .networkUnavailable:
            return "Please check your internet connection and try again."
        case .watchNotConnected, .watchNotReachable:
            return "Make sure your Apple Watch is nearby, paired, and unlocked."
        case .microphoneAccessDenied:
            return "Go to Settings > Privacy > Microphone to enable access."
        case .fileNotFound:
            return "The file may have been moved or deleted."
        case .insufficientStorage:
            return "Please free up storage space and try again."
        default:
            return "Please try again or contact support if the problem persists."
        }
    }
}


extension Result {
    func mapError<E: Error>(_ transform: (E) -> AppError) -> Result<Success, AppError> where Failure == E {
        mapError { error in
            transform(error)
        }
    }
}


#if DEBUG
struct ErrorLogger {
    static func log(_ error: AppError, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        print("🔴 Error in \(fileName):\(line) \(function)")
        print("   \(error.errorDescription ?? "Unknown error")")
        if let suggestion = error.recoverySuggestion {
            print("   💡 \(suggestion)")
        }
    }
}
#endif
