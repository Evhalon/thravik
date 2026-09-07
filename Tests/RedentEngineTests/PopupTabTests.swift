import Foundation
import RedentKit
import Testing
import WebKit
@testable import RedentEngine

@Suite("Popup tabs")
@MainActor
struct PopupTabTests {
    private func controller() -> TabController {
        TabController(session: BrowserSession(), settings: BrowserSettings(), logger: QuietPopupLogger())
    }

    /// WebKit hands the opener's own controller to `createWebViewWith`. Sharing
    /// it would let the popup's bridge registration displace the opener's.
    @Test("A popup gets its own content controller")
    func popupControllerIsSeparate() {
        let opener = WebViewFactory.makeConfiguration(
            store: .nonPersistent(), blocksTrackers: false, contentBlocker: nil
        )
        let shared = opener.userContentController
        let popup = WebViewFactory.makePopupView(
            configuration: opener, blocksTrackers: false, contentBlocker: nil
        )
        #expect(popup.configuration.userContentController !== shared)
        #expect(popup.configuration.applicationNameForUserAgent == BrowserUserAgent.safariApplicationName)
    }

    /// The tab takes the view WebKit prepared rather than building its own:
    /// only that view carries the opener link the sign-in reports back through.
    @Test("The popup tab adopts the prepared view instead of reloading")
    func popupTabAdoptsPreparedView() throws {
        let browser = controller()
        let parent = try #require(browser.newTab(url: URL(string: "https://example.com")) as? WebTab)
        let signIn = try #require(URL(string: "https://accounts.google.com/o/oauth2/auth"))
        let tab = browser.openPopupTab(
            configuration: WKWebViewConfiguration(), url: signIn, of: parent.snapshot
        )
        #expect(!tab.isHibernated)
        #expect(tab.webView != nil)
        #expect(tab.snapshot.containerID == parent.snapshot.containerID)
        #expect(BrowserUserAgent.normalized(tab.webView?.customUserAgent) == nil)
    }

    /// A `window.open()` with no address still has to become a tab: OAuth
    /// flows open the blank window first and navigate it afterwards.
    @Test("A blank popup still opens a tab")
    func blankPopupOpensTab() throws {
        let browser = controller()
        let parent = try #require(browser.newTab(url: URL(string: "https://example.com")) as? WebTab)
        let tab = browser.openPopupTab(configuration: WKWebViewConfiguration(), url: nil, of: parent.snapshot)
        #expect(browser.webTabs.contains { $0.id == tab.id })
        #expect(tab.snapshot.parentTabID == parent.id)
    }
}

private struct QuietPopupLogger: EventLogging {
    func debug(_ message: @autoclosure () -> String) {}
    func notice(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}
