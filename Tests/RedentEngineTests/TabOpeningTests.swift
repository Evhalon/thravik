import Foundation
import RedentKit
import Testing
import WebKit
@testable import RedentEngine

/// Guards the two things that make opening a tab feel instant.
@Suite("Opening tabs")
@MainActor
struct TabOpeningTests {
    private func controller() -> TabController {
        TabController(session: BrowserSession(), settings: BrowserSettings(), logger: HushedLogger())
    }

    @Test("A tab with no address builds no web view at all")
    func blankTabStaysAsleep() throws {
        let browser = controller()
        let tab = try #require(browser.newTab(url: nil) as? WebTab)
        #expect(tab.isHibernated)
        #expect(tab.webView == nil)
    }

    @Test("A tab with an address wakes immediately")
    func addressedTabWakes() throws {
        let browser = controller()
        let url = try #require(URL(string: "https://example.com"))
        let tab = try #require(browser.newTab(url: url) as? WebTab)
        #expect(!tab.isHibernated)
    }

    @Test("The warm spare is only handed to a tab in the same data store")
    func warmSpareRespectsIsolation() async {
        let warmer = WebViewWarmer()
        let store = WKWebsiteDataStore.nonPersistent()
        warmer.prepare(store: store, blocksTrackers: true, contentBlocker: nil)

        var matched: WKWebView?
        for _ in 0..<40 {
            #expect(warmer.take(store: .nonPersistent(), blocksTrackers: true) == nil)
            #expect(warmer.take(store: store, blocksTrackers: false) == nil)
            matched = warmer.take(store: store, blocksTrackers: true)
            if matched != nil { break }
            try? await Task.sleep(for: .milliseconds(50))
        }
        #expect(matched != nil)
    }

    @Test("A spare is handed out once")
    func spareIsNotShared() async {
        let warmer = WebViewWarmer()
        let store = WKWebsiteDataStore.nonPersistent()
        warmer.prepare(store: store, blocksTrackers: true, contentBlocker: nil)
        let first = await waitForSpare(warmer, store: store)

        #expect(first != nil)
        #expect(warmer.take(store: store, blocksTrackers: true) == nil)
    }

    @Test("Command-click inherits Container and does not nest")
    func commandClickInheritsWithoutNesting() throws {
        let browser = controller()
        let container = UUID()
        let parent = try #require(browser.newTab(url: URL(string: "https://example.com")) as? WebTab)
        parent.snapshot.containerID = container
        let opened = browser.openCommandClickedLink(
            url: try #require(URL(string: "https://example.com/next")),
            from: parent.snapshot
        )
        #expect(opened.snapshot.containerID == container)
        #expect(opened.snapshot.parentTabID == nil)
        #expect(opened.snapshot.groupID == nil)
        #expect(browser.selectedID == opened.id)
        #expect(browser.selectedID != parent.id)
    }

    /// Prepare sleeps 300ms then hops back to the main actor; a fixed 500ms
    /// sleep loses that race when the suite is busy.
    private func waitForSpare(_ warmer: WebViewWarmer, store: WKWebsiteDataStore) async -> WKWebView? {
        for _ in 0..<40 {
            if let view = warmer.take(store: store, blocksTrackers: true) { return view }
            try? await Task.sleep(for: .milliseconds(50))
        }
        return nil
    }
}

private struct HushedLogger: EventLogging {
    func debug(_ message: @autoclosure () -> String) {}
    func notice(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}
