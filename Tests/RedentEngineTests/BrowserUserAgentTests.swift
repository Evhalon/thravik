import Foundation
import RedentKit
import Testing
import WebKit
@testable import RedentEngine

@Suite("Browser user agent")
@MainActor
struct BrowserUserAgentTests {
    @Test("Every page uses the system WebKit identity, not a Chrome label")
    func everyPageUsesSafariIdentity() throws {
        let github = try #require(URL(string: "https://github.com"))
        let video = try #require(URL(string: "https://example.com/watch"))
        let netflix = try #require(URL(string: "https://www.netflix.com/watch/123"))
        #expect(BrowserUserAgent.string(for: github) == nil)
        #expect(BrowserUserAgent.string(for: video) == nil)
        #expect(BrowserUserAgent.string(for: netflix) == nil)
    }

    @Test("YouTube short links and Music share the media exception")
    func youtubeFamilyIsMedia() throws {
        #expect(BrowserUserAgent.mediaDomains.contains("youtube.com"))
        #expect(BrowserUserAgent.mediaDomains.contains("youtu.be"))
    }

    @Test("A lookalike host does not inherit a media exception")
    func lookalikeKeepsTheBlocker() throws {
        let youtube = try #require(URL(string: "https://evil-youtube.com/watch"))
        let origin = try #require(Origin(url: youtube))
        #expect(!BrowserUserAgent.mediaDomains.contains(origin.registrableDomain))
    }

    /// The truncated agent WebKit ships by default is what Google reads as an
    /// embedded web view, and it is what the sign-in refuses.
    @Test("The native identity ends in a complete Safari suffix")
    func safariSuffixIsComplete() {
        let name = BrowserUserAgent.safariApplicationName
        #expect(name.hasPrefix("Version/"))
        #expect(name.hasSuffix(" Safari/605.1.15"))
        let view = WKWebView(frame: .zero, configuration: WebViewFactory.makeConfiguration(
            store: .nonPersistent(), blocksTrackers: false, contentBlocker: nil
        ))
        #expect(view.configuration.applicationNameForUserAgent == name)
        #expect(BrowserUserAgent.normalized(view.customUserAgent) == nil)
    }

    @Test("A leftover Chrome agent is cleared on the next navigation")
    func applyClearsChrome() throws {
        let view = WKWebView()
        view.customUserAgent = "Mozilla/5.0 Chrome/152.0.0.0"
        let any = try #require(URL(string: "https://example.com"))
        BrowserUserAgent.apply(to: view, for: any)
        #expect(BrowserUserAgent.normalized(view.customUserAgent) == nil)
    }

    /// The blocker steps aside for the video properties only: Search must not
    /// lose ad blocking just because Google's accounts need a real engine.
    @Test("The content-blocker exception covers media, not identity")
    func blockerExceptionStaysOnMedia() {
        let filters = BrowserUserAgent.mediaTopURLFilters
        #expect(filters.contains { $0.contains("youtube\\.com") })
        #expect(filters.contains { $0.contains("netflix\\.com") })
        #expect(!filters.contains { $0.contains("google\\.com") })
    }
}
