import Foundation
import RedentKit
import Testing
@testable import RedentVault

@Suite("Session cookie vault payload")
struct SessionCookieVaultCodecTests {
    @Test("Every Space's cookies round-trip through one payload")
    func roundTrip() throws {
        let work = UUID()
        let home = UUID()
        let vault = [
            work: [cookie("sid", domain: "crm.example")],
            home: [cookie("auth", domain: "mail.example"), cookie("pref", domain: "mail.example")]
        ]

        let decoded = try SessionCookieVaultCodec.decode(SessionCookieVaultCodec.encode(vault))

        #expect(decoded == vault)
    }

    @Test("Per-Space items from before the shared vault migrate by their account UUID")
    func legacyItemsMigrate() throws {
        let space = UUID()
        let cookies = [cookie("sid", domain: "crm.example")]
        let items = [
            KeychainStore.Item(account: space.uuidString, valueData: try JSONEncoder().encode(cookies), genericData: nil),
            KeychainStore.Item(account: "not-a-uuid", valueData: try JSONEncoder().encode(cookies), genericData: nil),
            KeychainStore.Item(account: UUID().uuidString, valueData: Data("garbage".utf8), genericData: nil)
        ]

        #expect(SessionCookieVaultCodec.decodeLegacy(items) == [space: cookies])
    }

    private func cookie(_ name: String, domain: String) -> StoredCookie {
        StoredCookie(
            name: name, value: "v-\(name)", domain: domain, path: "/",
            flags: (isSecure: true, isHTTPOnly: true)
        )
    }
}
