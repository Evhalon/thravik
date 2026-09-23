import AppKit
import WebKit

/// The direct parent WebKit uses when it adds an attached Web Inspector.
/// Keeping that parent stable lets the inspector follow its tab between
/// SwiftUI representable hosts.
final class WebViewHost: NSView {
    let webView: WKWebView

    init(webView: WKWebView) {
        self.webView = webView
        super.init(frame: .zero)
        clipsToBounds = false
        webView.translatesAutoresizingMaskIntoConstraints = true
        webView.autoresizingMask = [.width, .height]
        webView.postsFrameChangedNotifications = true
        webView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        webView.setContentCompressionResistancePriority(.fittingSizeCompression, for: .horizontal)
        addSubview(webView)
        webView.frame = bounds
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func layout() {
        super.layout()
        fillWithWebView()
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        fillWithWebView()
    }

    /// The autoresizing mask only carries a size *delta* forward. Once the web
    /// view's frame drifts from the host's — WebKit handing it back after
    /// element fullscreen, or closing a docked inspector — the drift is kept
    /// for good, and the page lays out wider than the pane that shows it.
    /// A docked inspector is a sibling that WebKit lays out itself.
    private func fillWithWebView() {
        guard subviews.count == 1, webView.superview === self, webView.frame != bounds else { return }
        webView.frame = bounds
    }

    static func containing(_ webView: WKWebView) -> WebViewHost? {
        webView.superview as? WebViewHost
    }
}
