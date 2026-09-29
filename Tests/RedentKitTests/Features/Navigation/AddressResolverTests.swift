import Foundation
import Testing
@testable import RedentKit

@Suite("Address bar input resolution")
struct AddressResolverTests {
    @Test("Bare hosts become https URLs", arguments: [
        "example.com", "sub.example.co.uk", "example.com/path?x=1"
    ])
    func bareHost(_ input: String) throws {
        let url = try #require(AddressResolver.resolve(input, using: .duckduckgo))
        #expect(url.scheme == "https")
        #expect(url.absoluteString == "https://\(input)")
    }

    @Test("localhost with a port is treated as a host")
    func localhost() throws {
        let url = try #require(AddressResolver.resolve("localhost:3000", using: .duckduckgo))
        #expect(url.absoluteString == "https://localhost:3000")
    }

    @Test("Explicit schemes are preserved")
    func explicitScheme() throws {
        let url = try #require(AddressResolver.resolve("http://example.com", using: .duckduckgo))
        #expect(url.scheme == "http")
    }

    @Test("Prose becomes a search", arguments: [
        "how to cook rice", "swift 6 concurrency", "what is 2 + 2"
    ])
    func prose(_ input: String) throws {
        let url = try #require(AddressResolver.resolve(input, using: .duckduckgo))
        #expect(url.host() == "duckduckgo.com")
        #expect(url.absoluteString.contains("?q="))
    }

    @Test("An internationalized domain is treated as a host, not a search")
    func internationalizedHost() throws {
        let url = try #require(AddressResolver.resolve("пример.рф", using: .google))
        #expect(url.scheme == "https")
        #expect(url.host() != "www.google.com")
    }

    @Test("A trailing dot or a bare dot is not a host", arguments: ["example.", ".com", "..", "3.14"])
    func notAHost(_ input: String) throws {
        let url = try #require(AddressResolver.resolve(input, using: .google))
        #expect(url.host() == "www.google.com")
    }

    @Test("Empty input resolves to nothing", arguments: ["", "   ", "\n"])
    func empty(_ input: String) {
        #expect(AddressResolver.resolve(input, using: .duckduckgo) == nil)
    }

    @Test("Search terms are escaped, not injected")
    func escaping() throws {
        let url = try #require(AddressResolver.resolve("a&b=c?d#e", using: .duckduckgo))
        let query = try #require(url.query())
        #expect(!query.dropFirst(2).contains("&"))
        #expect(!query.contains("#"))
    }
}
