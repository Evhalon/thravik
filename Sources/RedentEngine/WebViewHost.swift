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

    /// Chrome's DevTools stand in for Safari's Web Inspector, yet WebKit still
    /// docks its own here when a path of its reaches it: both then show, and
    /// Safari's squeezes the page and Chrome's. It is hidden, not closed, so
    /// the connection DevTools shares stays up.
    override func didAddSubview(_ subview: NSView) {
        super.didAddSubview(subview)
        guard subview !== webView else { return }
        Task { [weak self] in self?.hideWebInspector() }
    }

    private func hideWebInspector() {
        guard webView.responds(to: NSSelectorFromString("_inspector")),
              let inspector = webView.value(forKey: "_inspector") as? NSObject,
              inspector.responds(to: NSSelectorFromString("hide"))
        else { return }
        inspector.perform(NSSelectorFromString("hide"))
        needsLayout = true
    }

    static func containing(_ webView: WKWebView) -> WebViewHost? {
        webView.superview as? WebViewHost
    }
}
