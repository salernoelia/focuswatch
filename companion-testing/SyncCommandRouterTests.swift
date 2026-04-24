import Foundation
import Testing

@testable import focuswatch_companion

@Suite("SyncCommandRouter")
struct SyncCommandRouterTests {
        @Test("Registered handler is invoked for matching action")
        func registeredHandlerIsInvokedForMatchingAction() {
            let router = SyncCommandRouter()
            var called = false
            router.register(action: "doThing") { _, _ in called = true }
            router.route(message: [SyncConstants.Keys.action: "doThing"], replyHandler: nil)
            #expect(called)
        }

        @Test("Route returns true for known action")
        func routeReturnsTrueForKnownAction() {
            let router = SyncCommandRouter()
            router.register(action: "known") { _, _ in }
            let result = router.route(message: [SyncConstants.Keys.action: "known"], replyHandler: nil)
            #expect(result)
        }

        @Test("Route returns false for unknown action")
        func routeReturnsFalseForUnknownAction() {
            let router = SyncCommandRouter()
            let result = router.route(message: [SyncConstants.Keys.action: "nope"], replyHandler: nil)
            #expect(!result)
        }

        @Test("Route returns false when action key is missing")
        func routeReturnsFalseWhenActionKeyMissing() {
            let router = SyncCommandRouter()
            router.register(action: "something") { _, _ in }
            let result = router.route(message: ["other": "val"], replyHandler: nil)
            #expect(!result)
        }

        @Test("Unregistered handler is not invoked")
        func unregisteredHandlerIsNotInvoked() {
            let router = SyncCommandRouter()
            var called = false
            router.register(action: "act") { _, _ in called = true }
            router.unregister(action: "act")
            router.route(message: [SyncConstants.Keys.action: "act"], replyHandler: nil)
            #expect(!called)
        }

        @Test("Reply handler is forwarded to registered handler")
        func replyHandlerIsForwardedToRegisteredHandler() {
            let router = SyncCommandRouter()
            var receivedReply: (([String: Any]) -> Void)? = nil
            router.register(action: "act") { _, reply in receivedReply = reply }
            let sentReply: ([String: Any]) -> Void = { _ in }
            router.route(message: [SyncConstants.Keys.action: "act"], replyHandler: sentReply)
            #expect(receivedReply != nil)
        }

        @Test("Multiple handlers for different actions are independent")
        func multipleHandlersForDifferentActionsAreIndependent() {
            let router = SyncCommandRouter()
            var calledA = false
            var calledB = false
            router.register(action: "A") { _, _ in calledA = true }
            router.register(action: "B") { _, _ in calledB = true }
            router.route(message: [SyncConstants.Keys.action: "A"], replyHandler: nil)
            #expect(calledA)
            #expect(!calledB)
        }

        @Test("Re-registering action replaces handler")
        func reregisteringActionReplacesHandler() {
            let router = SyncCommandRouter()
            var firstCalled = false
            var secondCalled = false
            router.register(action: "act") { _, _ in firstCalled = true }
            router.register(action: "act") { _, _ in secondCalled = true }
            router.route(message: [SyncConstants.Keys.action: "act"], replyHandler: nil)
            #expect(!firstCalled)
            #expect(secondCalled)
        }
}
