import Foundation
import RedentKit
import WebKit

/// WebKit is not Chrome. A Chrome label makes a site serve a Blink player —
/// YouTube dies, Netflix paints black, any `<video>` can. The honest Safari
/// identity is therefore the default for every page. The content blocker still
/// steps aside on known media properties: those players take themselves down
/// when their own scripts are filtered, which is a different problem.
@MainActor
enum BrowserUserAgent {

    /// Pages whose player dies if the content blocker stays on. Identity is
    /// already Safari everywhere; this list only lifts the blocker.
    static let mediaDomains: Set<String> = [
        "youtube.com", "youtu.be", "youtube-nocookie.com", "youtubekids.com",
        "netflix.com", "disneyplus.com", "hulu.com", "max.com", "hbomax.com",
        "primevideo.com", "twitch.tv", "vimeo.com", "dailymotion.com",
        "crunchyroll.com", "paramountplus.com", "peacocktv.com", "dazn.com",
        "tiktok.com", "plex.tv", "raiplay.it", "mediaset.it",
    ]

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

    /// Always `nil`: WebKit's own Safari string, which tracks the OS.
    static func string(for _: URL?) -> String? { nil }

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
