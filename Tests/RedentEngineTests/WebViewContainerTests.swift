import AppKit
import Testing
import WebKit
@testable import RedentEngine

@Suite("Web view container")
@MainActor
struct WebViewContainerTests {
    @Test("A hosted view fills the container, then shrinks with it")
    func hostedViewFillsThenShrinks() {
        let container = WebViewContainer(frame: NSRect(x: 0, y: 0, width: 1200, height: 800))
        let webView = makeView()
        container.attach(webView)
        container.layout()
        #expect(webView.frame.size == CGSize(width: 1200, height: 800))

        container.frame.size.width = 900
        container.layout()
        #expect(webView.frame.size == CGSize(width: 900, height: 800))
    }

    @Test("Container reports no intrinsic size even with a wide page")
    func containerIgnoresDocumentWidth() {
        let container = WebViewContainer(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
        let webView = makeView()
        webView.frame = NSRect(x: 0, y: 0, width: 1600, height: 900)
        container.attach(webView)
        #expect(container.intrinsicContentSize.width == NSView.noIntrinsicMetric)
        #expect(container.intrinsicContentSize.height == NSView.noIntrinsicMetric)
        #expect(webView.frame.size == CGSize(width: 400, height: 300))
    }

    @Test("Tearing down the host keeps a live view in the window")
    func detachingKeepsViewInWindow() {
        let window = makeWindow()
        let container = WebViewContainer(frame: window.contentView?.bounds ?? .zero)
        window.contentView?.addSubview(container)
        let webView = makeView()
        container.attach(webView)
        #expect(webView.window === window)

        container.removeFromSuperview()
        #expect(webView.window === window)
        #expect(webView.superview !== container)
    }

    @Test("Explicit release still lets the process go")
    func removeFromSuperviewLeavesPark() {
        let window = makeWindow()
        let container = WebViewContainer(frame: window.contentView?.bounds ?? .zero)
        window.contentView?.addSubview(container)
        let webView = makeView()
        container.attach(webView)
        container.removeFromSuperview()
        webView.removeFromSuperview()
        #expect(webView.superview == nil)
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled], backing: .buffered, defer: false
        )
        window.contentView = NSView(frame: window.contentLayoutRect)
        return window
    }

    private func makeView() -> WKWebView {
        WebViewFactory.makeWebView(configuration: WebViewFactory.makeConfiguration(
            store: .nonPersistent(), blocksTrackers: false, contentBlocker: nil
        ))
    }
}
