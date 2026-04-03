import Combine
import Foundation

final class ConnectivityTransportAdapter: SyncTransportProtocol {
    private let transport: ConnectivityTransport

    init(transport: ConnectivityTransport = .shared) {
        self.transport = transport
    }

    var isReachable: Bool {
        transport.isReachable
    }

    var contextReceivedPublisher: AnyPublisher<[String: Any], Never> {
        transport.contextReceived.eraseToAnyPublisher()
    }

    var messageReceivedPublisher: AnyPublisher<([String: Any], (([String: Any]) -> Void)?), Never> {
        transport.messageReceived.eraseToAnyPublisher()
    }

    var userInfoReceivedPublisher: AnyPublisher<[String: Any], Never> {
        transport.userInfoReceived.eraseToAnyPublisher()
    }

    var fileReceivedPublisher: AnyPublisher<(URL, [String: Any]?), Never> {
        transport.fileReceived.eraseToAnyPublisher()
    }

    func forceReconnect() {
        transport.forceReconnect()
    }

    func updateApplicationContext(_ context: [String: Any]) throws {
        try transport.updateApplicationContext(context)
    }

    func sendMessage(
        _ message: [String: Any],
        replyHandler: (([String: Any]) -> Void)?,
        errorHandler: ((Error) -> Void)?
    ) {
        transport.sendMessage(message, replyHandler: replyHandler, errorHandler: errorHandler)
    }

    func transferUserInfo(_ userInfo: [String: Any]) {
        transport.transferUserInfo(userInfo)
    }

    func getReceivedApplicationContext() -> [String: Any] {
        transport.getReceivedApplicationContext()
    }
}
