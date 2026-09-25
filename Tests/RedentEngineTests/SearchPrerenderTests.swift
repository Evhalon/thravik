import Foundation
import RedentKit
import Testing
import WebKit
@testable import RedentEngine

/// Return on a search shows the page loaded while the user paused typing,
/// instead of starting a second, slower load.
@Suite("Search prerender")
@MainActor
struct SearchPrerenderTests {
    @Test("A new tab for the prerendered search takes the finished page")
    func newTabAdoptsPage() async throws {
        let server = try SignedOutMediaServer(video: Data())
        defer { server.stop() }
        let url = try await server.start()
        let controller = makeController()
        var navigations = 0
        controller.onNavigation = { _, _ in navigations += 1 }

        controller.prerender(url)
        #expect(try await settles { server.pageRequestCount == 1 })
        let tab = try #require(controller.newTab(url: url) as? WebTab)

        #expect(try await settles { navigations == 1 })
        #expect(tab.webView?.url == url)
        // A fresh load would have asked the server a second time.
        try await Task.sleep(for: .milliseconds(300))
        #expect(server.pageRequestCount == 1)
        #expect(navigations == 1)
    }

    @Test("A tab opening somewhere else loads it fresh")
    func otherAddressLoadsFresh() async throws {
        let server = try SignedOutMediaServer(video: Data())
        defer { server.stop() }
        let url = try await server.start()
        let controller = makeController()

        controller.prerender(url)
        #expect(try await settles { server.pageRequestCount == 1 })
        controller.newTab(url: url.appending(path: "other"))

        #expect(try await settles { server.pageRequestCount == 2 })
    }

    @Test("A private window never loads a search ahead")
    func privateWindowSkips() throws {
        let controller = makeController(privateSessionID: UUID())
        let url = try #require(URL(string: "https://duckduckgo.com/?q=private"))
        controller.prerender(url)
        let store = controller.contexts.store(for: controller.spaceContext)
        #expect(!controller.warmer.prerenderer.isPrerendering(
            url, store: store, options: PageContentOptions(controller.settings)
        ))
    }

    private func settles(_ condition: () -> Bool) async throws -> Bool {
        for _ in 0..<250 {
            if condition() { return true }
            try await Task.sleep(for: .milliseconds(20))
        }
        return false
    }

    private func makeController(privateSessionID: UUID? = nil) -> TabController {
        TabController(
            session: BrowserSession(tabs: [TabSnapshot()], selectedTabID: nil),
            settings: BrowserSettings(),
            logger: SilentPrerenderLogger(),
            privateSessionID: privateSessionID
        )
    }
}

private struct SilentPrerenderLogger: EventLogging {
    func debug(_ message: @autoclosure () -> String) {}
    func notice(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}
