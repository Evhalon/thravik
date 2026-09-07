import Foundation
import Testing
import WebKit
@testable import RedentEngine

@Suite("Browser user agent")
@MainActor
struct BrowserUserAgentTests {
    @Test("YouTube uses the system WebKit identity, not a Chrome label")
    func youtubeDropsChromeLabel() throws {
        let url = try #require(URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ"))
        #expect(BrowserUserAgent.needsWebKitIdentity(url))
        #expect(BrowserUserAgent.string(for: url) == nil)
    }

    @Test("YouTube short links and Music share the same identity")
    func youtubeFamily() throws {
        let music = try #require(URL(string: "https://music.youtube.com/watch?v=abc"))
        let short = try #require(URL(string: "https://youtu.be/abc"))
        #expect(BrowserUserAgent.needsWebKitIdentity(music))
        #expect(BrowserUserAgent.needsWebKitIdentity(short))
    }

    @Test("Google sign-in is served the engine's own identity")
    func googleAccountsDropsChromeLabel() throws {
        let accounts = try #require(URL(string: "https://accounts.google.com/v3/signin/identifier"))
        let mail = try #require(URL(string: "https://mail.google.com/mail/u/0/"))
        let gmail = try #require(URL(string: "https://gmail.com"))
        #expect(BrowserUserAgent.string(for: accounts) == nil)
        #expect(BrowserUserAgent.string(for: mail) == nil)
        #expect(BrowserUserAgent.string(for: gmail) == nil)
    }

    @Test("A lookalike host does not inherit an identity domain")
    func lookalikeStaysChrome() throws {
        let youtube = try #require(URL(string: "https://evil-youtube.com/watch"))
        let google = try #require(URL(string: "https://accounts.google.com.evil.example/signin"))
        #expect(!BrowserUserAgent.needsWebKitIdentity(youtube))
        #expect(!BrowserUserAgent.needsWebKitIdentity(google))
        #expect(BrowserUserAgent.string(for: google) == BrowserUserAgent.compatibility)
    }

    @Test("Other sites keep a current Chrome compatibility string")
    func defaultIsCurrentChrome() throws {
        let url = try #require(URL(string: "https://github.com"))
        let ua = try #require(BrowserUserAgent.string(for: url))
        #expect(ua.contains("Chrome/152"))
        #expect(!ua.contains("Chrome/131"))
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
    }

    @Test("Applying a YouTube URL clears a previous Chrome agent")
    func applyClearsChromeOnYouTube() throws {
        let view = WKWebView()
        view.customUserAgent = BrowserUserAgent.compatibility
        let youtube = try #require(URL(string: "https://youtube.com"))
        BrowserUserAgent.apply(to: view, for: youtube)
        #expect(BrowserUserAgent.normalized(view.customUserAgent) == nil)
    }

    /// The blocker steps aside for the video properties only: a sign-in domain
    /// joining the identity set must not switch ad blocking off for Search.
    @Test("The content-blocker exception covers media, not identity")
    func blockerExceptionStaysOnMedia() {
        let filters = BrowserUserAgent.mediaTopURLFilters
        #expect(filters.contains { $0.contains("youtube\\.com") })
        #expect(!filters.contains { $0.contains("google\\.com") })
    }
}
