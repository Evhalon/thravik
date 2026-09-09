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

    static func containing(_ webView: WKWebView) -> WebViewHost? {
        webView.superview as? WebViewHost
    }
}
