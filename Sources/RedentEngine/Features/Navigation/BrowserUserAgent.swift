import Foundation
import RedentKit
import WebKit

/// Safari remains the default because Chrome-specific players can require Blink.
/// The internal Octane installation gets a narrowly scoped compatibility label.
@MainActor
enum BrowserUserAgent {

    /// `WKWebView`'s own agent stops at `(KHTML, like Gecko)` unless the app
    /// names itself, and Google reads that truncated string as an embedded web
    /// view just the same. The native identity therefore has to end in a real
    /// Safari suffix. Safari's marketing version has tracked macOS's since 26,
    /// which is this app's floor, so the OS supplies it.
    static var safariApplicationName: String {
        let os = ProcessInfo.processInfo.operatingSystemVersion
        return "Version/\(os.majorVersion).\(os.minorVersion) Safari/605.1.15"
    }

    static func string(for url: URL?) -> String? {
        guard let url,
              ["http", "https"].contains(url.scheme?.lowercased()),
              url.host?.lowercased() == "octane.gbm.lan" else { return nil }
        return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
            + "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36"
    }

    static func apply(to webView: WKWebView, for url: URL?) {
        webView.customUserAgent = string(for: url)
    }

    /// The header is stamped when WebKit builds the request for a navigation it
    /// has already asked us about, so switching the agent here is what serves
    /// the destination — not the page it came from. Sub-frames are left alone:
    /// the agent belongs to the web view, and a frame must not repaint the
    /// identity its top document was served under.
    static func applyBeforeNavigation(_ action: WKNavigationAction, on webView: WKWebView) {
        guard action.targetFrame?.isMainFrame == true else { return }
        apply(to: webView, for: action.request.url)
    }

    /// WebKit reports a cleared agent as `""`, not `nil`.
    static func normalized(_ ua: String?) -> String? {
        guard let ua, !ua.isEmpty else { return nil }
        return ua
    }
}
