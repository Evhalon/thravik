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

    private func makeView() -> WKWebView {
        WebViewFactory.makeWebView(configuration: WebViewFactory.makeConfiguration(
            store: .nonPersistent(), blocksTrackers: false, contentBlocker: nil
        ))
    }
}
