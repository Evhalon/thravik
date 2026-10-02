import AppKit
import Testing
import WebKit
@testable import RedentEngine

@Suite("Web view host")
@MainActor
struct WebViewHostTests {
    @Test("A web view handed back at the wrong size is snapped to the pane")
    func driftedWebViewIsRefilled() {
        let container = WebViewContainer(frame: NSRect(x: 0, y: 0, width: 900, height: 700))
        let webView = makeView()
        container.attach(webView)
        webView.frame = NSRect(x: 0, y: 0, width: 1400, height: 900)

        container.setFrameSize(NSSize(width: 800, height: 700))

        #expect(webView.frame.size == CGSize(width: 800, height: 700))
    }

    @Test("A host layout pass alone restores the fill")
    func layoutRefills() throws {
        let container = WebViewContainer(frame: NSRect(x: 0, y: 0, width: 900, height: 700))
        let webView = makeView()
        container.attach(webView)
        let host = try #require(WebViewHost.containing(webView))
        webView.frame = NSRect(x: 0, y: 0, width: 1400, height: 900)

        host.layout()

        #expect(webView.frame == host.bounds)
    }

    @Test("Switching tabs reuses their hosts and keeps both in the browser window")
    func tabSwitchReusesHosts() throws {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 700),
            styleMask: [.titled], backing: .buffered, defer: false
        )
        let container = WebViewContainer(frame: window.contentView?.bounds ?? .zero)
        window.contentView?.addSubview(container)
        let first = makeView()
        let second = makeView()
        container.attach(first)
        let firstHost = try #require(WebViewHost.containing(first))
        container.attach(second)
        let secondHost = try #require(WebViewHost.containing(second))
        container.attach(first)

        #expect(first.window === window)
        #expect(second.window === window)
        #expect(WebViewHost.containing(first) === firstHost)
        #expect(WebViewHost.containing(second) === secondHost)
        #expect(firstHost.superview === container)
        #expect(!firstHost.isHidden)
        #expect(secondHost.isHidden)
        #expect(first.frame == container.bounds)
    }

    private func makeView() -> WKWebView {
        WebViewFactory.makeWebView(configuration: WebViewFactory.makeConfiguration(
            store: .nonPersistent(), options: PageContentOptions(blocksTrackers: false), contentBlocker: nil
        ))
    }
}
