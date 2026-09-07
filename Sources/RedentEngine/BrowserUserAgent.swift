import Foundation
import RedentKit
import WebKit

/// WebKit is not Chrome. A Chrome label on this engine makes YouTube serve a
/// Blink player that later dies with a "browser error", and makes Google's
/// sign-in refuse the browser outright — "this browser or app may not be
/// secure". Corporate allow-lists still demand that label, so it stays the
/// default; the properties that check the engine behind it get the system
/// Safari string instead.
@MainActor
enum BrowserUserAgent {
    static let compatibility =
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 " +
        "(KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36"

    /// Properties whose player needs the real engine — and the only ones the
    /// content blocker steps aside for.
    static let mediaDomains: Set<String> = [
        "youtube.com", "youtu.be", "youtube-nocookie.com", "youtubekids.com"
    ]

    /// Sign-in surfaces that check the engine behind the label. Google reads a
    /// Chrome string on WebKit as an embedded web view and refuses the login,
    /// so its whole family — search, Gmail, the OAuth consent screen — is
    /// served the honest identity, and so are the popups those flows open.
    static let identityDomains: Set<String> = [
        "google.com", "gmail.com", "googlemail.com"
    ]

    static var webKitIdentityDomains: Set<String> { mediaDomains.union(identityDomains) }

    /// `WKWebView`'s own agent stops at `(KHTML, like Gecko)` unless the app
    /// names itself, and Google reads that truncated string as an embedded web
    /// view just the same. The native identity therefore has to end in a real
    /// Safari suffix. Safari's marketing version has tracked macOS's since 26,
    /// which is this app's floor, so the OS supplies it.
    static var safariApplicationName: String {
        let os = ProcessInfo.processInfo.operatingSystemVersion
        return "Version/\(os.majorVersion).\(os.minorVersion) Safari/605.1.15"
    }

    /// Content-blocker `if-top-url` filters matching those media properties.
    static var mediaTopURLFilters: [String] {
        mediaDomains.map { domain in
            "^https://([^/]*\\.)?\(NSRegularExpression.escapedPattern(for: domain))/"
        }
    }

    /// `nil` restores WebKit's own Safari string, which tracks the OS.
    static func string(for url: URL?) -> String? {
        needsWebKitIdentity(url) ? nil : compatibility
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

    static func needsWebKitIdentity(_ url: URL?) -> Bool {
        guard let url, let origin = Origin(url: url) else { return false }
        return webKitIdentityDomains.contains(origin.registrableDomain)
    }
}
