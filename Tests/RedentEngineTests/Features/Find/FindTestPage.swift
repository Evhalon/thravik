import AppKit
import Foundation
import RedentKit
import Testing
import WebKit
@testable import RedentEngine

/// A real tab showing a small page, once the find script has reached it.
@MainActor
enum FindTestPage {
    /// Tabs are built with `inactiveSchedulingPolicy = .suspend`, and a view
    /// outside a window counts as inactive: on a loaded CI runner WebKit could
    /// suspend the page before its load ever ran. Find is only used on a page
    /// that is on screen, so the test page is too. Kept for the process's life
    /// because nothing else retains a window that is only ordered in.
    private static var windows: [NSWindow] = []

    static func saying(_ body: String, head: String = "") async throws -> WebTab {
        let controller = TabController(
            session: BrowserSession(tabs: [TabSnapshot()], selectedTabID: nil),
            settings: BrowserSettings(),
            logger: QuietFindLogger()
        )
        let tab = try #require(controller.webTabs.first)
        tab.wake(loading: nil)
        let view = try #require(tab.webView)
        // A real viewport, so a match can be off screen and need revealing.
        show(view, width: 800, height: 600)
        view.loadHTMLString("<head>\(head)</head><body>\(body)</body>", baseURL: URL(string: "https://example.com"))
        // Generous, because a loaded runner can stall every web view for tens
        // of seconds. Never reload to recover: a slow first load would land
        // later and wipe the find state mid-test.
        if try await pageIsReady(view, within: .seconds(60)) { return tab }
        Issue.record("The find script never reached the page")
        return tab
    }

    private static func show(_ view: WKWebView, width: CGFloat, height: CGFloat) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled], backing: .buffered, defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView = view
        window.orderFrontRegardless()
        windows.append(window)
    }

    /// Settled too, so no pending navigation can replace the page under the test.
    private static func pageIsReady(_ view: WKWebView, within limit: Duration) async throws -> Bool {
        let deadline = ContinuousClock.now + limit
        while ContinuousClock.now < deadline {
            let ready = try? await view.callAsyncJavaScript(
                "return typeof window.redentFind === 'function' && !!document.body",
                in: nil,
                contentWorld: PageScripts.contentWorld
            ) as? Bool
            if ready == true, !view.isLoading { return true }
            try await Task.sleep(for: .milliseconds(20))
        }
        return false
    }
}

private struct QuietFindLogger: EventLogging {
    func debug(_ message: @autoclosure () -> String) {}
    func notice(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}
