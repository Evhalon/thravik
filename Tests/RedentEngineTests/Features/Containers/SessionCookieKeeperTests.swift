import Foundation
import RedentKit
import Testing
import WebKit
@testable import RedentEngine

@Suite("Session cookies across relaunch")
@MainActor
struct SessionCookieKeeperTests {
    @Test("Saved session cookies are back in the store before the first load")
    func restoresBeforeLoad() async throws {
        let container = UUID()
        let saved = StoredCookie(
            name: "LWSSO", value: "token", domain: "octane.example.lan", path: "/",
            flags: (isSecure: false, isHTTPOnly: true)
        )
        let storage = MemoryCookieStorage(cookies: [container: [saved]])
        let registry = BrowsingContextRegistry(sessionCookies: storage)
        let context = BrowsingContext.container(container)
        let store = registry.store(for: context)

        let restoration = try #require(registry.cookieRestoration(for: context))
        await restoration.value

        let names = await store.httpCookieStore.allCookies().map(\.name)
        #expect(names.contains("LWSSO"))
        #expect(registry.cookieRestoration(for: context) == nil)
    }

    /// WebKit notifies only the first cookie change, so a sign-in after it
    /// was never saved and the user was signed out at the next launch.
    @Test("Every sign-in during a session is saved, not only the first")
    func savesLaterSignIns() async throws {
        let container = UUID()
        let storage = MemoryCookieStorage(cookies: [:])
        let registry = BrowsingContextRegistry(sessionCookies: storage)
        let context = BrowsingContext.container(container)
        let cookies = registry.store(for: context).httpCookieStore
        await registry.cookieRestoration(for: context)?.value

        for token in ["first", "second"] {
            await cookies.setCookie(try #require(Self.sessionCookie(value: token)))
            await registry.flushSessionCookies()
        }

        let saved = await storage.load(container: container)
        #expect(saved.map(\.value) == ["second"])
    }

    private static func sessionCookie(value: String) -> HTTPCookie? {
        StoredCookie(
            name: "SESSION", value: value, domain: "app.example.lan", path: "/",
            flags: (isSecure: false, isHTTPOnly: true)
        ).httpCookie
    }

    @Test("A private window never restores or keeps session cookies")
    func ephemeralIsIgnored() {
        let registry = BrowsingContextRegistry(sessionCookies: MemoryCookieStorage(cookies: [:]))
        let context = BrowsingContext.ephemeral(UUID())
        _ = registry.store(for: context)
        #expect(registry.cookieRestoration(for: context) == nil)
    }
}

private actor MemoryCookieStorage: SessionCookieStoring {
    private var cookies: [UUID: [StoredCookie]]

    init(cookies: [UUID: [StoredCookie]]) { self.cookies = cookies }

    func load(container: UUID) -> [StoredCookie] { cookies[container] ?? [] }
    func save(_ cookies: [StoredCookie], container: UUID) { self.cookies[container] = cookies }
    func remove(container: UUID) { cookies[container] = nil }
}
