import Foundation
import Testing
@testable import RedentKit

@Suite("Stored cookie")
struct StoredCookieTests {
    @Test("A session cookie survives the round trip with its flags")
    func sessionCookieRoundTrips() throws {
        let original = try #require(HTTPCookie(properties: [
            .name: "sid", .value: "abc", .domain: ".example.com", .path: "/app",
            .secure: "TRUE", HTTPCookiePropertyKey("HttpOnly"): "TRUE",
        ]))
        let stored = try #require(StoredCookie(original))
        let data = try JSONEncoder().encode(stored)
        let restored = try #require(try JSONDecoder().decode(StoredCookie.self, from: data).httpCookie)

        #expect(restored.name == "sid")
        #expect(restored.value == "abc")
        #expect(restored.domain == ".example.com")
        #expect(restored.path == "/app")
        #expect(restored.isSecure)
        #expect(restored.isHTTPOnly)
        #expect(restored.isSessionOnly)
    }

    @Test("A cookie with an expiry is left to WebKit's own storage")
    func persistentCookieIsSkipped() throws {
        let cookie = try #require(HTTPCookie(properties: [
            .name: "pref", .value: "1", .domain: "example.com", .path: "/",
            .expires: Date.now.addingTimeInterval(3600),
        ]))
        #expect(StoredCookie(cookie) == nil)
    }
}
