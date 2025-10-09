import Foundation

enum ErrorLogger {
  static func log(
    _ error: AppError, file: String = #file, function: String = #function, line: Int = #line
  ) {
    #if DEBUG
      let fileName = (file as NSString).lastPathComponent
      print("❌ [\(fileName):\(line)] \(function)")
      print("   Error: \(error.localizedDescription)")
      if let recoverySuggestion = error.recoverySuggestion {
        print("   Suggestion: \(recoverySuggestion)")
      }
    #endif
  }

  static func log(
    _ message: String, file: String = #file, function: String = #function, line: Int = #line
  ) {
    #if DEBUG
      let fileName = (file as NSString).lastPathComponent
      print("ℹ️ [\(fileName):\(line)] \(function)")
      print("   \(message)")
    #endif
  }
}
