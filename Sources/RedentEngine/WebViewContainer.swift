import AppKit
import WebKit

/// Sizes its WebKit host in `layout()` rather than with constraints.
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
        // Clipping here also clips WebKit's video layer. Fullscreen and
        // in-page players then go black the moment they composite a new frame.
        clipsToBounds = false
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
        guard hostedView?.webView !== webView else { fillHostedView(); return }
        if let webView {
            // WebKit lifts the view into its own window for element fullscreen
            // and returns it on exit; re-adopting it while it is up there would
            // drag the video straight back out. The test is the window, not the
            // superview: a view sitting in another of *our* containers is just
            // a tab changing panes, and this container has to take it.
            if let hostWindow = webView.window, let ownWindow = window, hostWindow !== ownWindow { return }
            parkHostedView()
            let host = WebViewHost.containing(webView) ?? WebViewHost(webView: webView)
            host.isHidden = false
            addSubview(host)
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

    /// A frame change does not schedule `layout()`, and SwiftUI only calls
    /// `updateNSView` when something it observes changed — neither happens while
    /// the user drags the window edge. Without this the WebKit host kept the width
    /// it was born with and the page had to be scrolled sideways to be read.
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        fillHostedView()
    }

    private func fillHostedView() {
        guard let hosted = hostedView, hosted.frame != bounds else { return }
        hosted.frame = bounds
    }

    private func parkHostedView() {
        guard let hosted = hostedView else {
            subviews.forEach { $0.removeFromSuperview() }
            return
        }
        WebViewWindowPark.park(hosted, from: window)
    }

    private var hostedView: WebViewHost? { subviews.first as? WebViewHost }
}
