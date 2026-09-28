import Foundation
import RedentKit
import Testing
import WebKit
@testable import RedentEngine

/// Most searches start from a tab already showing a page. The results page
/// loaded while typing must serve those too, without costing the tab its past.
@Suite("Search prerender in a live tab")
@MainActor
struct SearchPrerenderLiveTabTests {
    @Test("A tab showing a page takes the prerendered search without asking again")
    func liveTabAdoptsPage() async throws {
        let (server, controller, tab, first) = try await openedTab()
        defer { server.stop() }
        let search = first.appending(path: "search")

        controller.prerender(search)
        #expect(try await settles { server.pageRequestCount == 2 })
        tab.load(search)

        #expect(tab.webView?.url == search)
        #expect(tab.url == search)
        try await Task.sleep(for: .milliseconds(300))
        #expect(server.pageRequestCount == 2)
    }

    @Test("Back returns to the page the search replaced, and Forward to the search")
    func backAndForwardCrossTheSwap() async throws {
        let (server, controller, tab, first) = try await openedTab()
        defer { server.stop() }
        let search = first.appending(path: "search")
        controller.prerender(search)
        #expect(try await settles { server.pageRequestCount == 2 })
        tab.load(search)
        #expect(tab.canGoBack)

        tab.goBack()
        #expect(tab.webView?.url == first)
        #expect(tab.url == first)
        #expect(tab.canGoForward)

        tab.goForward()
        #expect(tab.webView?.url == search)
        #expect(!tab.canGoForward)
        // Neither step reloaded anything: both pages were still there.
        #expect(server.pageRequestCount == 2)
    }

    @Test("Hibernating lets go of the replaced page too")
    func hibernationReleasesDisplacedPages() async throws {
        let (server, controller, tab, first) = try await openedTab()
        defer { server.stop() }
        let search = first.appending(path: "search")
        controller.prerender(search)
        #expect(try await settles { server.pageRequestCount == 2 })
        tab.load(search)

        tab.hibernate()

        #expect(!tab.displacedPages.canGoBack)
        #expect(!tab.displacedPages.canGoForward)
    }

    private func openedTab() async throws -> (SignedOutMediaServer, TabController, WebTab, URL) {
        let server = try SignedOutMediaServer(video: Data())
        let url = try await server.start()
        let controller = TabController(
            session: BrowserSession(tabs: [TabSnapshot()], selectedTabID: nil),
            settings: BrowserSettings(),
            logger: SilentLiveTabLogger()
        )
        let tab = try #require(controller.newTab(url: url) as? WebTab)
        #expect(try await settles { server.pageRequestCount == 1 && tab.webView?.isLoading == false })
        return (server, controller, tab, url)
    }

    private func settles(_ condition: () -> Bool) async throws -> Bool {
        for _ in 0..<250 {
            if condition() { return true }
            try await Task.sleep(for: .milliseconds(20))
        }
        return false
    }
}

private struct SilentLiveTabLogger: EventLogging {
    func debug(_ message: @autoclosure () -> String) {}
    func notice(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}
