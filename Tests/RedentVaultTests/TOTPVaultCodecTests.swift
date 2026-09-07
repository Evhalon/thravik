import Foundation
import RedentKit
import Testing
@testable import RedentVault

@Suite("TOTP vault payload")
struct TOTPVaultCodecTests {
    private func sample(_ tag: Int) -> TOTPAccount {
        TOTPAccount(
            issuer: "Issuer\(tag)",
            accountName: "user\(tag)@example.com",
            secret: Data((0..<20).map { UInt8(($0 + tag) % 256) }),
            linkedDomains: tag.isMultiple(of: 2) ? ["example.com"] : []
        )
    }

    @Test("Many accounts round-trip in one payload")
    func largeRoundtrip() throws {
        let accounts = (0..<50).map(sample)
        let decoded = try TOTPVaultCodec.decode(TOTPVaultCodec.encode(accounts))
        #expect(decoded == accounts)
    }

    @Test("Corrupt payload is rejected")
    func corruptPayload() {
        #expect(throws: VaultError.invalidData) {
            try TOTPVaultCodec.decode(Data("not-json".utf8))
        }
    }
}
