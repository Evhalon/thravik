import Foundation
import RedentKit
import Testing
@testable import RedentVault

@Suite("Credential vault payload")
struct CredentialVaultCodecTests {
    @Test("Two hundred imported logins use one round-trippable payload")
    func largeImportRoundtrip() throws {
        let credentials = (0..<200).map { index in
            Credential(
                origin: Origin(scheme: "https", host: "site\(index).example"),
                username: "user\(index)",
                password: "password\(index)"
            )
        }

        let decoded = try CredentialVaultCodec.decode(CredentialVaultCodec.encode(credentials))

        #expect(decoded == credentials)
    }

    @Test("Corrupt payload is rejected")
    func corruptPayload() {
        #expect(throws: VaultError.invalidData) {
            try CredentialVaultCodec.decode(Data("not-json".utf8))
        }
    }
}
