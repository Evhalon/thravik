import Foundation

/// Wire types this reader understands, from the protobuf wire format spec.
/// `.startGroup`/`.endGroup` (3/4) are legacy and never emitted by protoc —
/// encountering one is treated as a malformed stream by the caller.
enum ProtobufWireType: UInt64 {
    case varint = 0
    case fixed64 = 1
    case lengthDelimited = 2
    case fixed32 = 5
}

enum ProtobufError: Error {
    case truncated
    case malformedVarint
    case unknownWireType(UInt64)
}

/// Minimal protobuf wire-format reader: varints and length-delimited fields,
/// plus skipping for wire types we don't otherwise decode. This is a generic
/// reader, not OTP-specific — it knows nothing about `MigrationPayload`.
struct ProtobufReader {
    private let bytes: [UInt8]
    private var offset = 0

    init(data: Data) {
        self.bytes = [UInt8](data)
    }

    var isAtEnd: Bool { offset >= bytes.count }

    mutating func readTag() throws -> (fieldNumber: Int, wireType: ProtobufWireType) {
        let tag = try readVarint()
        guard let wireType = ProtobufWireType(rawValue: tag & 0x7) else {
            throw ProtobufError.unknownWireType(tag & 0x7)
        }
        return (Int(tag >> 3), wireType)
    }

    mutating func readVarint() throws -> UInt64 {
        var result: UInt64 = 0
        var shift: UInt64 = 0
        while true {
            guard offset < bytes.count else { throw ProtobufError.truncated }
            let byte = bytes[offset]
            offset += 1
            result |= UInt64(byte & 0x7F) << shift
            if byte & 0x80 == 0 { return result }
            shift += 7
            guard shift < 64 else { throw ProtobufError.malformedVarint }
        }
    }

    mutating func readLengthDelimited() throws -> Data {
        let length = try readVarint()
        guard length <= UInt64(bytes.count - offset) else { throw ProtobufError.truncated }
        let end = offset + Int(length)
        defer { offset = end }
        return Data(bytes[offset..<end])
    }

    mutating func skip(_ wireType: ProtobufWireType) throws {
        switch wireType {
        case .varint: _ = try readVarint()
        case .fixed64: try advance(by: 8)
        case .lengthDelimited: _ = try readLengthDelimited()
        case .fixed32: try advance(by: 4)
        }
    }

    private mutating func advance(by count: Int) throws {
        guard offset + count <= bytes.count else { throw ProtobufError.truncated }
        offset += count
    }
}
