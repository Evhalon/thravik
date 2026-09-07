import Testing
import Foundation
import RedentKit
@testable import RedentOTPAuth

@Suite struct OTPAuthURIParserTests {
    private let importer = OTPAuthImporter()

    @Test func issuerFromLabel() throws {
        let uri = "otpauth://totp/Example:alice@example.com?secret=JBSWY3DPEHPK3PXP&digits=6&period=30"
        let accounts = try importer.accounts(fromScannedText: uri)
        #expect(accounts.count == 1)
        #expect(accounts[0].issuer == "Example")
        #expect(accounts[0].accountName == "alice@example.com")
        #expect(accounts[0].algorithm == .sha1)
        #expect(accounts[0].digits == 6)
        #expect(accounts[0].period == 30)
    }

    @Test func issuerQueryParamWinsOverLabel() throws {
        let uri = "otpauth://totp/OldIssuer:alice@example.com?secret=JBSWY3DPEHPK3PXP&issuer=NewIssuer"
        let accounts = try importer.accounts(fromScannedText: uri)
        #expect(accounts[0].issuer == "NewIssuer")
        #expect(accounts[0].accountName == "alice@example.com")
    }

    @Test func encodedColonInLabel() throws {
        let uri = "otpauth://totp/Example%3A%20alice@example.com?secret=JBSWY3DPEHPK3PXP"
        let accounts = try importer.accounts(fromScannedText: uri)
        #expect(accounts[0].issuer == "Example")
        #expect(accounts[0].accountName == "alice@example.com")
    }

    @Test func hotpSchemeIsRejected() {
        let uri = "otpauth://hotp/Example:alice@example.com?secret=JBSWY3DPEHPK3PXP&counter=0"
        #expect(throws: OTPImportError.counterBasedNotSupported) {
            try importer.accounts(fromScannedText: uri)
        }
    }

    @Test func missingSecretIsMalformed() {
        let uri = "otpauth://totp/Example:alice@example.com?issuer=Example"
        #expect(throws: OTPImportError.malformedPayload) {
            try importer.accounts(fromScannedText: uri)
        }
    }

    @Test func unsupportedSchemeIsRejected() {
        #expect(throws: OTPImportError.unsupportedScheme) {
            try importer.accounts(fromScannedText: "https://example.com")
        }
    }

    @Test func explicitAlgorithmAndDigits() throws {
        let uri = "otpauth://totp/Ex:alice?secret=JBSWY3DPEHPK3PXP&algorithm=SHA256&digits=8"
        let accounts = try importer.accounts(fromScannedText: uri)
        #expect(accounts[0].algorithm == .sha256)
        #expect(accounts[0].digits == 8)
    }
}
