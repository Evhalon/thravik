import Foundation
import RedentKit
import Testing
import WebKit
@testable import RedentEngine

@Suite("Browser user agent")
@MainActor
struct BrowserUserAgentTests {
    @Test("Public pages use the system WebKit identity")
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
        #expect(MediaRuleExceptions.mediaDomains.contains("youtube.com"))
        #expect(MediaRuleExceptions.mediaDomains.contains("youtu.be"))
    }

    @Test("A lookalike host does not inherit a media exception")
    func lookalikeKeepsTheBlocker() throws {
        let youtube = try #require(URL(string: "https://evil-youtube.com/watch"))
        let origin = try #require(Origin(url: youtube))
        #expect(!MediaRuleExceptions.mediaDomains.contains(origin.registrableDomain))
    }

    /// The truncated agent WebKit ships by default is what Google reads as an
    /// embedded web view, and it is what the sign-in refuses.
    @Test("The native identity ends in a complete Safari suffix")
    func safariSuffixIsComplete() {
        let name = BrowserUserAgent.safariApplicationName
        #expect(name.hasPrefix("Version/"))
        #expect(name.hasSuffix(" Safari/605.1.15"))
        let view = WKWebView(frame: .zero, configuration: WebViewFactory.makeConfiguration(
            store: .nonPersistent(), options: PageContentOptions(blocksTrackers: false), contentBlocker: nil
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

    @Test("Octane uses Chrome identity on HTTP and HTTPS")
    func octaneUsesChromeIdentity() throws {
        for address in [
            "http://octane.gbm.lan:8080/ui/?p=2001/1003#entity-navigation",
            "https://OCTANE.GBM.LAN/ui/"
        ] {
            let url = try #require(URL(string: address))
            let agent = try #require(BrowserUserAgent.string(for: url))
            #expect(agent.contains("Chrome/"))
        }
    }

    @Test("Octane exception excludes lookalikes, subdomains and other schemes")
    func octaneExceptionIsExact() throws {
        for address in [
            "http://evil-octane.gbm.lan:8080/ui/",
            "http://octane.gbm.lan.example.com/ui/",
            "http://child.octane.gbm.lan/ui/",
            "ftp://octane.gbm.lan/ui/"
        ] {
            let url = try #require(URL(string: address))
            #expect(BrowserUserAgent.string(for: url) == nil)
        }
        #expect(BrowserUserAgent.string(for: nil) == nil)
    }

    @Test("Leaving Octane restores Safari identity on the same web view")
    func leavingOctaneRestoresSafari() throws {
        let view = WKWebView()
        let octane = try #require(URL(string: "http://octane.gbm.lan:8080/ui/"))
        BrowserUserAgent.apply(to: view, for: octane)
        #expect(view.customUserAgent?.contains("Chrome/") == true)
        let other = try #require(URL(string: "https://example.com"))
        BrowserUserAgent.apply(to: view, for: other)
        #expect(BrowserUserAgent.normalized(view.customUserAgent) == nil)
    }

    /// The blocker steps aside for the video properties only: Search must not
    /// lose ad blocking just because Google's accounts need a real engine.
    @Test("The content-blocker exception covers media, not identity")
    func blockerExceptionStaysOnMedia() {
        let filters = MediaRuleExceptions.mediaTopURLFilters
        #expect(filters.contains { $0.contains("youtube\\.com") })
        #expect(filters.contains { $0.contains("netflix\\.com") })
        #expect(!filters.contains { $0.contains("google\\.com") })
    }
}
