import Foundation

/// Writes an Apple icon file from PNG renditions. The format is a four-byte
/// magic and length, then one typed, length-prefixed chunk per size — simple
/// enough that shelling out to `iconutil` would be the heavier choice.
enum ICNSEncoder {
    /// Each chunk type with the pixel size macOS expects inside it.
    static let renditions: [(type: String, pixels: Int)] = [
        ("icp4", 16), ("icp5", 32), ("icp6", 64), ("ic07", 128), ("ic08", 256),
        ("ic09", 512), ("ic10", 1024), ("ic11", 32), ("ic12", 64), ("ic13", 256), ("ic14", 512)
    ]

    static func encode(_ chunks: [(type: String, png: Data)]) -> Data {
        var body = Data()
        for chunk in chunks {
            body.append(Data(chunk.type.utf8.prefix(4)))
            body.append(bigEndian: UInt32(chunk.png.count + 8))
            body.append(chunk.png)
        }
        var file = Data("icns".utf8)
        file.append(bigEndian: UInt32(body.count + 8))
        file.append(body)
        return file
    }
}

private extension Data {
    mutating func append(bigEndian value: UInt32) {
        Swift.withUnsafeBytes(of: value.bigEndian) { append(contentsOf: $0) }
    }
}
