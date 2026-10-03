import Foundation
import Testing
@testable import RedentSync

struct SyncPasswordCryptographyTests {
    @Test func pbkdf2MatchesIndependentSHA256Vector() throws {
        let key = try SyncPasswordKeyDerivation().derive(password: "password", salt: Data("salt".utf8))
        let hex = key.withUnsafeBytes { bytes in bytes.map { String(format: "%02x", $0) }.joined() }
        #expect(hex == "669cfe52482116fda1aa2cbe409b2f56c8e4563752b7a28f6eaab614ee005178")
    }

    @Test func wrapsRecoveryCodeWithRandomAccountBoundEnvelope() throws {
        let crypto = SyncPasswordCryptography()
        let code = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef-01234567"
        let accountID = UUID()
        let first = try crypto.wrap(recoveryCode: code, password: "a long master password", accountID: accountID)
        let second = try crypto.wrap(recoveryCode: code, password: "a long master password", accountID: accountID)
        #expect(first.salt.count == 32)
        #expect(first.salt != second.salt)
        #expect(first.iterations == 600_000)
        #expect(try crypto.unwrap(envelope: first, password: "a long master password", accountID: accountID) == code)
    }

    @Test func rejectsWrongPasswordAndAccount() throws {
        let crypto = SyncPasswordCryptography()
        let code = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef-01234567"
        let accountID = UUID()
        let envelope = try crypto.wrap(recoveryCode: code, password: "a long master password", accountID: accountID)
        #expect(throws: SyncPasswordCryptographyError.authenticationFailed) {
            try crypto.unwrap(envelope: envelope, password: "a different master password", accountID: accountID)
        }
        #expect(throws: SyncPasswordCryptographyError.authenticationFailed) {
            try crypto.unwrap(envelope: envelope, password: "a long master password", accountID: UUID())
        }
    }

    @Test func rejectsUntrustedKDFParametersAndWeakPasswords() throws {
        let crypto = SyncPasswordCryptography()
        let code = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef-01234567"
        let envelope = try crypto.wrap(recoveryCode: code, password: "a long master password", accountID: UUID())
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(envelope)) as? [String: Any])
        json["iterations"] = 1
        let altered = try JSONDecoder().decode(PasswordKeyEnvelope.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(throws: SyncPasswordCryptographyError.invalidEnvelope) {
            try crypto.unwrap(envelope: altered, password: "a long master password", accountID: UUID())
        }
        #expect(throws: SyncPasswordCryptographyError.invalidPassword) {
            try crypto.wrap(recoveryCode: code, password: "short", accountID: UUID())
        }
    }
}
