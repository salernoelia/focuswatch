import Foundation
import WatchKit

class PomodoroExtendedRuntimeSessionDelegate: NSObject, WKExtendedRuntimeSessionDelegate {
  static let shared = PomodoroExtendedRuntimeSessionDelegate()
  private override init() {}

  func extendedRuntimeSessionDidStart(_ session: WKExtendedRuntimeSession) {}
  func extendedRuntimeSessionWillExpire(_ session: WKExtendedRuntimeSession) {}
  func extendedRuntimeSession(
    _ session: WKExtendedRuntimeSession,
    didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?
  ) {}
}
