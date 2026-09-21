import RedentKit
import WebKit

/// Decides whether a main-frame navigation should be re-issued without its
/// tracking parameters.
///
/// Only plain GETs are rewritten: a form POST, a reload, or a back/forward
/// step must reach the server exactly as the page asked for it.
@MainActor
enum TrackingLinkCleaner {
    static func cleanTarget(of action: WKNavigationAction, enabled: Bool) -> URL? {
        guard enabled,
              (action.request.httpMethod ?? "GET").uppercased() == "GET",
              action.navigationType != .reload,
              action.navigationType != .backForward,
              let url = action.request.url
        else { return nil }
        return TrackingParameters.stripped(url)
    }

    static func clean(_ url: URL, enabled: Bool) -> URL {
        guard enabled else { return url }
        return TrackingParameters.stripped(url) ?? url
    }
}
