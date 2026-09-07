import Testing
import Foundation
import RedentKit
@testable import RedentOTPAuth

/// Builds byte-accurate `MigrationPayload` protobuf fixtures by hand, so
/// these tests exercise the real wire format rather than trusting our own
/// encoder to mirror our own decoder.
@Suite struct MigrationDecoderTests {
    private let importer = OTPAuthImporter()

    @Test func decodesTOTPEntryAndSkipsHOTPEntry() throws {
        let totpSecret = Data([0xDE, 0xAD, 0xBE, 0xEF, 0x01, 0x02, 0x03, 0x04])
        let hotpSecret = Data([0x01, 0x02, 0x03, 0x04])

        let totpEntry = encodeOtpParameters(
            secret: totpSecret, name: "alice@example.com", issuer: "Example",
            algorithm: 2, digits: 2, type: 2, counter: nil
        )
        let hotpEntry = encodeOtpParameters(
            secret: hotpSecret, name: "bob", issuer: "",
            algorithm: 1, digits: 1, type: 1, counter: 5
        )

        let uri = migrationURI(entries: [totpEntry, hotpEntry])
        let accounts = try importer.accounts(fromScannedText: uri)

        #expect(accounts.count == 1)
        #expect(accounts[0].secret == totpSecret)
        #expect(accounts[0].issuer == "Example")
        #expect(accounts[0].accountName == "alice@example.com")
        #expect(accounts[0].digits == 8)
        #expect(accounts[0].algorithm == .sha256)
        #expect(accounts[0].period == 30)
    }

    @Test func splitsNameWhenIssuerFieldEmpty() throws {
        let entry = encodeOtpParameters(
            secret: Data([0x01]), name: "Example: alice", issuer: "",
            algorithm: 0, digits: 0, type: 2, counter: nil
        )
        let accounts = try importer.accounts(fromScannedText: migrationURI(entries: [entry]))
        #expect(accounts[0].issuer == "Example")
        #expect(accounts[0].accountName == "alice")
        #expect(accounts[0].algorithm == .sha1)
        #expect(accounts[0].digits == 6)
    }

    @Test func emptyParameterListThrowsEmptyPayload() {
        #expect(throws: OTPImportError.emptyPayload) {
            try importer.accounts(fromScannedText: migrationURI(entries: []))
        }
    }

    @Test func truncatedPayloadThrowsMalformed() {
        // Tag for field 1 (length-delimited), followed by an unterminated varint length.
        let bad = Data([0x0A, 0xFF, 0xFF])
        let uri = "otpauth-migration://offline?data=\(bad.base64EncodedString())"
        #expect(throws: OTPImportError.malformedPayload) {
            try importer.accounts(fromScannedText: uri)
        }
    }

    // MARK: - Fixture encoding

    private func migrationURI(entries: [Data]) -> String {
        var payload = Data()
        for entry in entries {
            payload.append(lengthDelimitedField(number: 1, bytes: entry))
        }
        let base64 = payload.base64EncodedString()
        let allowed = CharacterSet.urlQueryAllowed
        let encoded = base64.addingPercentEncoding(withAllowedCharacters: allowed) ?? base64
        return "otpauth-migration://offline?data=\(encoded)"
    }

    private func encodeOtpParameters(
        secret: Data, name: String, issuer: String,
        algorithm: UInt64, digits: UInt64, type: UInt64, counter: UInt64?
    ) -> Data {
        var data = Data()
        data.append(lengthDelimitedField(number: 1, bytes: secret))
        data.append(lengthDelimitedField(number: 2, bytes: Data(name.utf8)))
        if !issuer.isEmpty {
            data.append(lengthDelimitedField(number: 3, bytes: Data(issuer.utf8)))
        }
        data.append(varintField(number: 4, value: algorithm))
        data.append(varintField(number: 5, value: digits))
        data.append(varintField(number: 6, value: type))
        if let counter {
            data.append(varintField(number: 7, value: counter))
        }
        return data
    }

    private func varint(_ value: UInt64) -> Data {
        var remaining = value
        var bytes: [UInt8] = []
        repeat {
            var byte = UInt8(remaining & 0x7F)
            remaining >>= 7
            if remaining != 0 { byte |= 0x80 }
            bytes.append(byte)
        } while remaining != 0
        return Data(bytes)
    }

    private func tag(number: Int, wireType: UInt8) -> Data {
        varint((UInt64(number) << 3) | UInt64(wireType))
    }

    private func lengthDelimitedField(number: Int, bytes: Data) -> Data {
        var data = tag(number: number, wireType: 2)
        data.append(varint(UInt64(bytes.count)))
        data.append(bytes)
        return data
    }

    private func varintField(number: Int, value: UInt64) -> Data {
        var data = tag(number: number, wireType: 0)
        data.append(varint(value))
        return data
    }
}
