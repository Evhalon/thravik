import Foundation
import RedentKit
import Testing
@testable import RedentEngine

/// Through a real navigation: the rewrite happens in the policy callback, which
/// no unit of pure code can stand in for. `.invalid` never resolves, so the
/// test needs no network — the address is settled before the request goes out.
/// `attemptedURL` is read because a failed load clears the view's own `url`.
@Suite("Tracking links")
@MainActor
struct TrackingLinkTests {
    private let dirty = URL(string: "https://shop.invalid/item?id=7&utm_source=mail&fbclid=x")

    @Test("A link loads without its tracking parameters")
    func stripsOnNavigation() async throws {
        let tab = try await navigate(stripping: true)
        #expect(tab.attemptedURL?.absoluteString == "https://shop.invalid/item?id=7")
        #expect(tab.webView?.isLoading == false)
    }

    @Test("With the setting off, the link loads exactly as written")
    func leavesAloneWhenOff() async throws {
        let tab = try await navigate(stripping: false)
        #expect(tab.attemptedURL == dirty)
    }

    private func navigate(stripping: Bool) async throws -> WebTab {
        var settings = BrowserSettings()
        settings.stripsTrackingParameters = stripping
        let controller = TabController(
            session: BrowserSession(tabs: [TabSnapshot()], selectedTabID: nil),
            settings: settings, logger: QuietLinkLogger()
        )
        let tab = try #require(controller.webTabs.first)
        tab.load(try #require(dirty))
        let view = try #require(tab.webView)
        // Settled once WebKit has given up on the unresolvable host; a rewrite,
        // if there is one, is issued before that and restarts the load.
        for _ in 0..<250 {
            try await Task.sleep(for: .milliseconds(20))
            if !view.isLoading, tab.attemptedURL != dirty || !stripping { break }
        }
        return tab
    }
}

private struct QuietLinkLogger: EventLogging {
    func debug(_ message: @autoclosure () -> String) {}
    func notice(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}
