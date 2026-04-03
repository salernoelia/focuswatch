import Combine
import Foundation
import WatchConnectivity

final class WCSessionFileTransferReference: SyncFileTransferReference {
    let transfer: WCSessionFileTransfer

    init(transfer: WCSessionFileTransfer) {
        self.transfer = transfer
    }

    var metadata: [String: Any]? {
        transfer.file.metadata
    }
}

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

    var fileTransferFinishedPublisher: AnyPublisher<(SyncFileTransferReference, Error?), Never> {
        transport.fileTransferFinished
            .map { transfer, error in
                (
                    WCSessionFileTransferReference(transfer: transfer) as SyncFileTransferReference,
                    error
                )
            }
            .eraseToAnyPublisher()
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

    @discardableResult
    func transferFile(_ fileURL: URL, metadata: [String: Any]?) -> SyncFileTransferReference? {
        guard let transfer = transport.transferFile(fileURL, metadata: metadata) else {
            return nil
        }
        return WCSessionFileTransferReference(transfer: transfer)
    }

    func outstandingFileTransferCount() -> Int {
        transport.outstandingFileTransfers().count
    }

    func cancelAllFileTransfers() {
        transport.cancelAllFileTransfers()
    }
}
