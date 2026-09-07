import Foundation
import Testing
@testable import RedentKit

@Suite("Origin and public-suffix handling")
struct OriginTests {
    private func makeOrigin(_ raw: String) throws -> Origin {
        let url = try #require(URL(string: raw))
        return try #require(Origin(url: url))
    }

    @Test("Registrable domain collapses subdomains")
    func collapsesSubdomains() throws {
        let origin = try makeOrigin("https://mail.google.com/inbox")
        #expect(origin.registrableDomain == "google.com")
    }

    @Test("Multi-label suffixes are respected")
    func multiLabelSuffix() throws {
        let origin = try makeOrigin("https://shop.example.co.uk")
        #expect(origin.registrableDomain == "example.co.uk")
    }

    @Test("A lookalike domain never matches the real one")
    func lookalikeDoesNotMatch() throws {
        let real = try makeOrigin("https://google.com")
        let fake = try makeOrigin("https://evil-google.com")
        #expect(!real.matches(fake))
        #expect(!fake.matches(real))
    }

    @Test("Subdomains of the same site match each other")
    func subdomainsMatch() throws {
        let a = try makeOrigin("https://accounts.github.com")
        let b = try makeOrigin("https://github.com/login")
        #expect(a.matches(b))
    }

    @Test("Non-web schemes are rejected", arguments: [
        "file:///Users/me/page.html", "javascript:alert(1)", "about:blank"
    ])
    func rejectsNonWebSchemes(_ raw: String) throws {
        #expect(Origin(url: try #require(URL(string: raw))) == nil)
    }

    @Test("IP literals have no registrable domain")
    func ipLiteral() throws {
        let origin = try makeOrigin("http://192.168.1.4:8080")
        #expect(origin.registrableDomain == "192.168.1.4")
    }

    @Test("Display host drops the www prefix")
    func displayHost() throws {
        let origin = try makeOrigin("https://www.bbc.co.uk")
        #expect(origin.displayHost == "bbc.co.uk")
    }
}
