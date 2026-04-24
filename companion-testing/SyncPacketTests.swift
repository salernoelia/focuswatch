import Foundation
import Testing

@testable import focuswatch_companion

@Suite("SyncPacket Encoding")
struct SyncPacketTests {
        @Test("Encode and decode preserves all fields")
        func encodeAndDecodePreservesAllFields() throws {
            let payload = try JSONEncoder().encode(["key": "value"])
            let timestamp = Date(timeIntervalSince1970: 1_000_000)
            let metadata = ["k1": "v1", "k2": "v2"]
            let packet = SyncPacket(
                type: .checklist,
                payload: payload,
                timestamp: timestamp,
                metadata: metadata
            )

            let data = try packet.encode()
            let decoded = try SyncPacket.decode(from: data)

            #expect(decoded.type == packet.type)
            #expect(decoded.payload == packet.payload)
            #expect(decoded.timestamp.timeIntervalSince1970 == packet.timestamp.timeIntervalSince1970)
            #expect(decoded.metadata == packet.metadata)
        }

        @Test("Encode and decode with nil metadata")
        func encodeAndDecodeWithNilMetadata() throws {
            let packet = SyncPacket(type: .level, payload: Data([1, 2, 3]), metadata: nil)
            let decoded = try SyncPacket.decode(from: try packet.encode())
            #expect(decoded.metadata == nil)
        }

        @Test("Decode from data produces identical value to encode")
        func decodeFromDataProducesIdenticalValue() throws {
            let packet = SyncPacket(type: .calendar, payload: Data("hello".utf8), metadata: ["a": "b"])
            let encoded = try packet.encode()
            let decoded = try SyncPacket.decode(from: encoded)
            #expect(decoded.type == packet.type)
            #expect(decoded.payload == packet.payload)
            #expect(decoded.metadata == packet.metadata)
        }

        @Test("Encoded data is valid JSON")
        func encodedDataIsValidJSON() throws {
            let packet = SyncPacket(type: .config, payload: Data(), metadata: nil)
            let data = try packet.encode()
            let json = try JSONSerialization.jsonObject(with: data)
            #expect(json is [String: Any])
        }

        @Test("All SyncMessageTypes survive round-trip")
        func allMessageTypesRoundTrip() throws {
            let types: [SyncMessageType] = [.calendar, .checklist, .level, .config, .auth, .telemetry, .command, .watchUUID]
            for type_ in types {
                let packet = SyncPacket(type: type_, payload: Data())
                let decoded = try SyncPacket.decode(from: try packet.encode())
                #expect(decoded.type == type_)
            }
        }
}
