import Foundation
import Testing
@testable import RedentKit

@Suite("Managed URL blocklist")
struct ManagedURLBlocklistTests {
    private func url(_ raw: String) throws -> URL {
        try #require(URL(string: raw))
    }

    @Test("Matches registrable domain and subdomains")
    func domainMatch() throws {
        let patterns = ["evil.com"]
        #expect(ManagedURLBlocklist.isBlocked(url: try url("https://shop.evil.com/x"), patterns: patterns))
        #expect(!ManagedURLBlocklist.isBlocked(url: try url("https://notevil.com/"), patterns: patterns))
    }

    @Test("Does not substring-match")
    func noSubstring() throws {
        let patterns = ["evil.com"]
        #expect(!ManagedURLBlocklist.isBlocked(url: try url("https://notevil.com/"), patterns: patterns))
    }

    @Test("A subdomain pattern blocks only that host, not its siblings")
    func subdomainPatternStaysNarrow() throws {
        let patterns = ["mail.example.com"]
        #expect(ManagedURLBlocklist.isBlocked(url: try url("https://mail.example.com/inbox"), patterns: patterns))
        #expect(!ManagedURLBlocklist.isBlocked(url: try url("https://www.example.com/"), patterns: patterns))
        #expect(!ManagedURLBlocklist.isBlocked(url: try url("https://example.com/"), patterns: patterns))
    }

    @Test("URL-shaped and mixed-case patterns normalize to their host")
    func urlPatterns() throws {
        let patterns = [" HTTPS://Evil.com/path?x=1 "]
        #expect(ManagedURLBlocklist.isBlocked(url: try url("http://EVIL.com:8080/"), patterns: patterns))
        #expect(!ManagedURLBlocklist.isBlocked(url: try url("https://evil.com.attacker.test/"), patterns: patterns))
    }

    @Test("Non-web schemes are never blocked")
    func nonWebSchemes() throws {
        #expect(!ManagedURLBlocklist.isBlocked(url: try url("about:blank"), patterns: ["evil.com"]))
    }

    @Test("Empty patterns never block")
    func emptyPatterns() throws {
        #expect(!ManagedURLBlocklist.isBlocked(url: try url("https://example.com/"), patterns: []))
    }
}
