import Foundation
import RedentKit
import Testing
@testable import RedentVault

@Suite("TOTP Keychain payload")
struct KeychainTOTPCodecTests {
    private func sample() -> TOTPAccount {
        TOTPAccount(
            issuer: "Google",
            accountName: "very.long.email.address@gmail.com",
            secret: Data((0..<20).map { UInt8($0) })
        )
    }

    @Test("An account survives without kSecAttrGeneric")
    func roundtripWithoutGeneric() throws {
        let account = sample()
        let data = try KeychainTOTPCodec.encode(account)
        #expect(data.count > 64)
        let item = KeychainStore.Item(
            account: account.id.uuidString, valueData: data, genericData: nil
        )
        let decoded = try #require(KeychainTOTPCodec.decode(item))
        #expect(decoded.issuer == account.issuer)
        #expect(decoded.accountName == account.accountName)
        #expect(decoded.secret == account.secret)
    }

    @Test("Legacy generic + raw secret still decodes")
    func legacyGeneric() throws {
        let account = sample()
        let generic = try JSONEncoder().encode(TOTPMetadata(account: account))
        let item = KeychainStore.Item(
            account: account.id.uuidString,
            valueData: account.secret,
            genericData: generic
        )
        let decoded = try #require(KeychainTOTPCodec.decode(item))
        #expect(decoded.secret == account.secret)
        #expect(decoded.issuer == "Google")
    }
}
