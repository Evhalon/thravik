import Foundation
import RedentKit

/// Decodes Google Authenticator's `MigrationPayload` protobuf:
///
///     MigrationPayload { repeated OtpParameters otp_parameters = 1; … }
///     OtpParameters { bytes secret=1; string name=2; string issuer=3;
///                     enum algorithm=4; enum digits=5; enum type=6; int64 counter=7; }
enum MigrationDecoder {
    static func decode(base64: String) throws -> [TOTPAccount] {
        guard let data = decodedBase64(base64) else { throw OTPImportError.malformedPayload }

        let entries = try readEntries(from: data)
        guard !entries.isEmpty else { throw OTPImportError.emptyPayload }

        return try entries.compactMap { try decodeEntry($0) }
    }

    private static func readEntries(from data: Data) throws -> [Data] {
        var reader = ProtobufReader(data: data)
        var entries: [Data] = []
        do {
            while !reader.isAtEnd {
                let tag = try reader.readTag()
                if tag.fieldNumber == 1, tag.wireType == .lengthDelimited {
                    entries.append(try reader.readLengthDelimited())
                } else {
                    try reader.skip(tag.wireType)
                }
            }
        } catch {
            throw OTPImportError.malformedPayload
        }
        return entries
    }

    /// Returns `nil` for entries this importer intentionally skips (HOTP
    /// counters, MD5 digests) rather than failing the whole batch.
    private static func decodeEntry(_ data: Data) throws -> TOTPAccount? {
        var reader = ProtobufReader(data: data)
        var secret: Data?
        var name = ""
        var issuer = ""
        var algorithmRaw: UInt64 = 0
        var digitsRaw: UInt64 = 0
        var typeRaw: UInt64 = 0

        do {
            while !reader.isAtEnd {
                let tag = try reader.readTag()
                switch tag.fieldNumber {
                case 1: secret = try reader.readLengthDelimited()
                case 2: name = decodedString(try reader.readLengthDelimited())
                case 3: issuer = decodedString(try reader.readLengthDelimited())
                case 4: algorithmRaw = try reader.readVarint()
                case 5: digitsRaw = try reader.readVarint()
                case 6: typeRaw = try reader.readVarint()
                default: try reader.skip(tag.wireType)
                }
            }
        } catch {
            throw OTPImportError.malformedPayload
        }

        guard typeRaw != 1 else { return nil }              // hotp: not supported
        guard let secretData = secret else { throw OTPImportError.malformedPayload }
        guard let algorithm = mappedAlgorithm(algorithmRaw) else { return nil }  // md5: unsupported

        let (resolvedIssuer, account) = resolvedIssuerAndAccount(name: name, issuer: issuer)
        return TOTPAccount(
            issuer: resolvedIssuer, accountName: account, secret: secretData,
            algorithm: algorithm, digits: mappedDigits(digitsRaw), period: 30
        )
    }

    private static func mappedAlgorithm(_ raw: UInt64) -> TOTPAlgorithm? {
        switch raw {
        case 0, 1: return .sha1
        case 2: return .sha256
        case 3: return .sha512
        default: return nil   // 4 = md5, or an algorithm added after this was written
        }
    }

    private static func mappedDigits(_ raw: UInt64) -> Int {
        raw == 2 ? 8 : 6   // 0 = unspecified, 1 = six, 2 = eight
    }

    private static func resolvedIssuerAndAccount(name: String, issuer: String) -> (issuer: String, account: String) {
        guard issuer.isEmpty, let colonIndex = name.firstIndex(of: ":") else {
            return (issuer, name)
        }
        let splitIssuer = String(name[..<colonIndex])
        var account = String(name[name.index(after: colonIndex)...])
        if account.hasPrefix(" ") { account.removeFirst() }
        return (splitIssuer, account)
    }

    private static func decodedString(_ data: Data) -> String {
        String(data: data, encoding: .utf8) ?? ""
    }

    /// Restores standard base64 padding the caller may have stripped, and
    /// tolerates `+`/`/` arriving pre-decoded from the URL's `data` param.
    private static func decodedBase64(_ string: String) -> Data? {
        let remainder = string.count % 4
        let padded = remainder == 0 ? string : string + String(repeating: "=", count: 4 - remainder)
        return Data(base64Encoded: padded)
    }
}
