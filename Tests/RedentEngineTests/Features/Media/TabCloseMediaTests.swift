import AppKit
import Foundation
import RedentKit
import Testing
import WebKit
@testable import RedentEngine

@Suite("Closing media tabs", .serialized)
@MainActor
struct TabCloseMediaTests {
    @Test("Closing suspends retained live and displaced players", arguments: [false, true])
    func closeStopsPlayback(withDisplacedPage: Bool) async throws {
        let browser = TabController(
            session: BrowserSession(), settings: BrowserSettings(), logger: SilentMediaLogger()
        )
        let tab = try #require(browser.newTab(url: nil) as? WebTab)
        tab.wake(loading: nil)
        let first = try #require(tab.webView)
        let firstWindow = try await playVideo(in: first)
        defer { firstWindow.close() }
        var retainedViews = [first]
        var secondWindow: NSWindow?
        defer { secondWindow?.close() }
        if withDisplacedPage {
            let second = makeView()
            tab.displaceLiveView(with: second)
            secondWindow = try await playVideo(in: second)
            retainedViews.append(second)
        }

        browser.close(tab.id)

        #expect(!browser.webTabs.contains { $0.id == tab.id })
        #expect(tab.webView == nil)
        #expect(tab.isHibernated)
        #expect(!tab.displacedPages.canGoBack)
        for view in retainedViews {
            #expect(await settles(view, at: .suspended))
        }
    }

    private func playVideo(in view: WKWebView) async throws -> NSWindow {
        let fixture = try #require(Bundle.module.url(
            forResource: "clip", withExtension: "mp4", subdirectory: "Fixtures"
        ))
        let encoded = try Data(contentsOf: fixture).base64EncodedString()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 150),
            styleMask: [.titled], backing: .buffered, defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView = WebViewHost(webView: view)
        window.orderFrontRegardless()
        view.loadHTMLString(
            "<video autoplay muted loop src='data:video/mp4;base64,\(encoded)'></video>", baseURL: nil
        )
        guard await settles(view, at: .playing) else {
            window.close()
            Issue.record("The fixture must be playing before testing close")
            throw PlaybackError.didNotStart
        }
        return window
    }

    private func settles(_ view: WKWebView, at state: WKMediaPlaybackState) async -> Bool {
        for _ in 0..<250 {
            if await view.requestMediaPlaybackState() == state { return true }
            try? await Task.sleep(for: .milliseconds(20))
        }
        return false
    }

    private func makeView() -> WKWebView {
        WebViewFactory.makeWebView(configuration: WebViewFactory.makeConfiguration(
            store: .nonPersistent(), options: PageContentOptions(), contentBlocker: nil
        ))
    }

    private enum PlaybackError: Error { case didNotStart }
}

private struct SilentMediaLogger: EventLogging {
    func debug(_ message: @autoclosure () -> String) {}
    func notice(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}
