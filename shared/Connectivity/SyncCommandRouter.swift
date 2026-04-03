import Foundation

final class SyncCommandRouter {
    typealias SyncHandler = ([String: Any], (([String: Any]) -> Void)?) -> Void

    private var handlers: [String: SyncHandler] = [:]

    func register(action: String, handler: @escaping SyncHandler) {
        handlers[action] = handler
    }

    func unregister(action: String) {
        handlers.removeValue(forKey: action)
    }

    @discardableResult
    func route(
        message: [String: Any],
        replyHandler: (([String: Any]) -> Void)?
    ) -> Bool {
        guard let action = message[SyncConstants.Keys.action] as? String,
              let handler = handlers[action]
        else {
            return false
        }

        handler(message, replyHandler)
        return true
    }
}
