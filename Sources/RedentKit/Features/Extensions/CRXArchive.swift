import Foundation

/// Unwraps a Chrome extension package (`.crx`) to the zip archive inside it.
///
/// A CRX is a small signed header followed by an ordinary zip. Version 3
/// stores one header length; version 2 stores a key and a signature length.
/// A plain zip is passed through, so a downloaded `.zip` installs the same way.
public enum CRXArchive {
    public enum Failure: Error, Equatable {
        case notAnExtensionPackage
        case unsupportedVersion(UInt32)
        case truncated
    }

    public static func zipPayload(of data: Data) throws(Failure) -> Data {
        let bytes = [UInt8](data)
        if bytes.starts(with: zipMagic) { return data }
        guard bytes.starts(with: crxMagic) else { throw .notAnExtensionPackage }
        let version = try word(bytes, at: 4)
        let start: Int
        switch version {
        case 3:
            start = 12 + Int(try word(bytes, at: 8))
        case 2:
            start = 16 + Int(try word(bytes, at: 8)) + Int(try word(bytes, at: 12))
        default:
            throw .unsupportedVersion(version)
        }
        guard start < bytes.count, bytes[start...].starts(with: zipMagic) else { throw .truncated }
        return Data(bytes[start...])
    }

    private static let crxMagic: [UInt8] = Array("Cr24".utf8)
    private static let zipMagic: [UInt8] = [0x50, 0x4B, 0x03, 0x04]

    /// Little-endian, as every field in the CRX header is.
    private static func word(_ bytes: [UInt8], at offset: Int) throws(Failure) -> UInt32 {
        guard offset + 4 <= bytes.count else { throw .truncated }
        return bytes[offset..<offset + 4].reversed().reduce(0) { $0 << 8 | UInt32($1) }
    }
}
