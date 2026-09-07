import AppKit
import WebKit

/// Sizes its web view in `layout()` rather than with constraints.
///
/// Constraints looked tidier but could not survive element fullscreen: WebKit
/// lifts the web view out into its own window and hands it back afterwards, and
/// constraints tying it to a container it has left are dropped for good — the
/// page came back the wrong size, or not at all. Laying out by frame also
/// sidesteps the reason constraints were used in the first place: an
/// autoresizing mask scales a size delta *proportionally* to what a subview
/// already has, which from a zero-sized container has nothing to scale.
///
/// Reports no intrinsic size so SwiftUI can shrink the host when the sidebar
/// opens. WKWebView otherwise publishes the document width and the page stays
/// that wide, forcing a horizontal scroll.
final class WebViewContainer: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        clipsToBounds = true
        setContentHuggingPriority(.defaultLow, for: .horizontal)
        setContentHuggingPriority(.defaultLow, for: .vertical)
        setContentCompressionResistancePriority(.fittingSizeCompression, for: .horizontal)
        setContentCompressionResistancePriority(.fittingSizeCompression, for: .vertical)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: NSView.noIntrinsicMetric)
    }

    func attach(_ webView: WKWebView?) {
        guard subviews.first !== webView else { fillHostedView(); return }
        if let webView {
            // WebKit lifts the view into its own window for element fullscreen
            // and returns it on exit; re-adopting it while it is up there would
            // drag the video straight back out. The test is the window, not the
            // superview: a view sitting in another of *our* containers is just
            // a tab changing panes, and this container has to take it.
            if let hostWindow = webView.window, let ownWindow = window, hostWindow !== ownWindow { return }
            parkHostedView()
            webView.isHidden = false
            webView.translatesAutoresizingMaskIntoConstraints = true
            webView.setContentHuggingPriority(.defaultLow, for: .horizontal)
            webView.setContentCompressionResistancePriority(.fittingSizeCompression, for: .horizontal)
            addSubview(webView)
            fillHostedView()
            return
        }
        parkHostedView()
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)
        if newWindow == nil { parkHostedView() }
    }

    override func layout() {
        super.layout()
        fillHostedView()
    }

    private func fillHostedView() {
        guard let hosted = subviews.first, hosted.frame != bounds else { return }
        hosted.frame = bounds
    }

    private func parkHostedView() {
        guard let hosted = subviews.first as? WKWebView else {
            subviews.forEach { $0.removeFromSuperview() }
            return
        }
        WebViewWindowPark.park(hosted, from: window)
    }
}

/// SwiftUI tears the host down on every tab or Space switch. Leaving a live
/// `WKWebView` with no window lets WebKit kill the content process, which is
/// why coming back to a Space reloaded every page. The park stays in the
/// window so the process stays.
@MainActor
private enum WebViewWindowPark {
    static let identifier = NSUserInterfaceItemIdentifier("redent.web-park")

    static func park(_ webView: WKWebView, from window: NSWindow?) {
        webView.isHidden = true
        webView.frame = .zero
        guard let window, let park = host(in: window) else {
            webView.removeFromSuperview()
            return
        }
        if webView.superview !== park { park.addSubview(webView) }
    }

    private static func host(in window: NSWindow) -> NSView? {
        let parent = window.contentView?.superview ?? window.contentView
        if let existing = parent?.subviews.first(where: { $0.identifier == identifier }) {
            return existing
        }
        let park = NSView(frame: .zero)
        park.identifier = identifier
        park.isHidden = true
        parent?.addSubview(park)
        return park
    }
}
