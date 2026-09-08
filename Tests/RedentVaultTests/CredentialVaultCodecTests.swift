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
                password: "password\(index)",
                spaceID: index.isMultiple(of: 2) ? BrowserSpace.workID : BrowserSpace.travelID
            )
        }

        let decoded = try CredentialVaultCodec.decode(CredentialVaultCodec.encode(credentials))

        #expect(decoded == credentials)
    }

    @Test("Logins written before Spaces were profiles join Work")
    func legacyLoginsJoinWork() throws {
        let legacy = """
        [{"id":"\(UUID().uuidString)","scheme":"https","host":"old.example",
        "username":"jane","password":"secret","createdAt":0,"useCount":0}]
        """
        let data = Data(legacy.replacingOccurrences(of: "\n", with: "").utf8)
        #expect(try CredentialVaultCodec.decode(data).first?.spaceID == BrowserSpace.workID)
    }

    @Test("Corrupt payload is rejected")
    func corruptPayload() {
        #expect(throws: VaultError.invalidData) {
            try CredentialVaultCodec.decode(Data("not-json".utf8))
        }
    }
}
