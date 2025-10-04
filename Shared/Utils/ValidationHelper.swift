import Foundation

enum ValidationHelper {
    
    /// Validates and sanitizes text input
    /// - Parameters:
    ///   - text: The text to validate
    ///   - fieldName: Name of the field for error messages
    ///   - minLength: Minimum required length (default: 1)
    ///   - maxLength: Maximum allowed length (default: 1000)
    /// - Returns: Result containing sanitized text or validation error
    static func validateText(
        _ text: String,
        fieldName: String,
        minLength: Int = AppConstants.Validation.minTextLength,
        maxLength: Int = AppConstants.Validation.maxTextLength
    ) -> Result<String, AppError> {
    
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        

        guard !trimmed.isEmpty else {
            return .failure(.emptyField(field: fieldName))
        }
        

        guard trimmed.count >= minLength else {
            return .failure(.textTooShort(field: fieldName, minLength: minLength))
        }
        

        guard trimmed.count <= maxLength else {
            return .failure(.textTooLong(field: fieldName, maxLength: maxLength))
        }
        
        return .success(trimmed)
    }
    
    /// Checks if text is valid without trimming
    /// - Parameters:
    ///   - text: The text to validate
    ///   - minLength: Minimum required length
    ///   - maxLength: Maximum allowed length
    /// - Returns: True if valid, false otherwise
    static func isValidText(
        _ text: String,
        minLength: Int = AppConstants.Validation.minTextLength,
        maxLength: Int = AppConstants.Validation.maxLength
    ) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count >= minLength && trimmed.count <= maxLength
    }
    
    /// Sanitizes text by trimming whitespace
    /// - Parameter text: The text to sanitize
    /// - Returns: Trimmed text
    static func sanitize(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Validates email format (basic check)
    /// - Parameter email: Email address to validate
    /// - Returns: Result containing email or validation error
    static func validateEmail(_ email: String) -> Result<String, AppError> {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            return .failure(.emptyField(field: "Email"))
        }
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        guard emailPredicate.evaluate(with: trimmed) else {
            return .failure(.invalidInput(field: "Email", reason: "Invalid email format"))
        }
        
        return .success(trimmed)
    }
    
    /// Validates that a string contains only alphanumeric characters and spaces
    /// - Parameters:
    ///   - text: Text to validate
    ///   - fieldName: Name of the field for error messages
    /// - Returns: Result containing validated text or error
    static func validateAlphanumeric(
        _ text: String,
        fieldName: String
    ) -> Result<String, AppError> {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            return .failure(.emptyField(field: fieldName))
        }
        
        let alphanumericSet = CharacterSet.alphanumerics.union(.whitespaces)
        guard trimmed.unicodeScalars.allSatisfy({ alphanumericSet.contains($0) }) else {
            return .failure(.invalidInput(field: fieldName, reason: "Must contain only letters, numbers, and spaces"))
        }
        
        return .success(trimmed)
    }
}
