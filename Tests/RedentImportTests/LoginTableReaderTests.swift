import Foundation
import Testing
@testable import RedentImport
import RedentKit

@Suite("Chromium login origin parsing")
struct LoginTableReaderTests {
    @Test("A full Chromium login URL reduces to its host")
    func loginURL() {
        let origin = LoginTableReader.origin(from: "https://www.github.com/login", realm: nil)
        #expect(origin?.host == "www.github.com")
        #expect(origin?.registrableDomain == "github.com")
    }

    @Test("signon_realm is used when origin_url is not a web origin")
    func realmFallback() {
        let origin = LoginTableReader.origin(
            from: "android://hash@com.github.app/",
            realm: "https://github.com/"
        )
        #expect(origin?.host == "github.com")
    }

    @Test("A path Foundation refuses still yields the host")
    func loosePath() {
        let origin = LoginTableReader.origin(from: "https://accounts.example.com/path with space", realm: nil)
        #expect(origin?.host == "accounts.example.com")
        #expect(origin?.registrableDomain == "example.com")
    }

    @Test("Subdomains still match the live site via eTLD+1")
    func subdomainMatchesLiveSite() throws {
        let stored = try #require(LoginTableReader.origin(
            from: "https://signin.amazon.com/ap/signin", realm: nil
        ))
        let url = try #require(URL(string: "https://www.amazon.com/"))
        let live = try #require(Origin(url: url))
        #expect(stored.matches(live))
    }
}
