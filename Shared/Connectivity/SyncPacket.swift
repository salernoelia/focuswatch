import Foundation

struct SyncPacket: Codable {
    let type: SyncMessageType
    let payload: Data
    let timestamp: Date
    let metadata: [String: String]?

    init(type: SyncMessageType, payload: Data, timestamp: Date = Date(), metadata: [String: String]? = nil) {
        self.type = type
        self.payload = payload
        self.timestamp = timestamp
        self.metadata = metadata
    }

    func encode() throws -> Data {
        try JSONEncoder().encode(self)
    }

    static func decode(from data: Data) throws -> SyncPacket {
        try JSONDecoder().decode(SyncPacket.self, from: data)
    }
}

