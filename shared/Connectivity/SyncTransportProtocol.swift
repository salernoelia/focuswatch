import Combine
import Foundation

protocol SyncFileTransferReference: AnyObject {
    var metadata: [String: Any]? { get }
}

protocol SyncTransportProtocol: AnyObject {
    var isReachable: Bool { get }

    var contextReceivedPublisher: AnyPublisher<[String: Any], Never> { get }
    var messageReceivedPublisher: AnyPublisher<([String: Any], (([String: Any]) -> Void)?), Never> { get }
    var userInfoReceivedPublisher: AnyPublisher<[String: Any], Never> { get }
    var fileReceivedPublisher: AnyPublisher<(URL, [String: Any]?), Never> { get }

    func forceReconnect()
    func updateApplicationContext(_ context: [String: Any]) throws
    func sendMessage(
        _ message: [String: Any],
        replyHandler: (([String: Any]) -> Void)?,
        errorHandler: ((Error) -> Void)?
    )
    func transferUserInfo(_ userInfo: [String: Any])
    func getReceivedApplicationContext() -> [String: Any]

    @discardableResult
    func transferFile(_ fileURL: URL, metadata: [String: Any]?) -> SyncFileTransferReference?
    func outstandingFileTransferCount() -> Int
    func cancelAllFileTransfers()

    var fileTransferFinishedPublisher: AnyPublisher<(SyncFileTransferReference, Error?), Never> { get }
}

extension SyncTransportProtocol {
    @discardableResult
    func transferFile(_ fileURL: URL, metadata: [String: Any]?) -> SyncFileTransferReference? {
        nil
    }

    func outstandingFileTransferCount() -> Int {
        0
    }

    func cancelAllFileTransfers() {
    }

    var fileTransferFinishedPublisher: AnyPublisher<(SyncFileTransferReference, Error?), Never> {
        Empty<(SyncFileTransferReference, Error?), Never>().eraseToAnyPublisher()
    }
}
