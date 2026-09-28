import WebKit

/// The views a tab stepped away from when it took over a prerendered search.
///
/// WebKit cannot hand one view's back list to another, so the view a search
/// replaced is kept, parked and paused, and Back steps into it. That is
/// faster than a back-forward cache hit: nothing is rebuilt at all.
///
/// Each view holds a content process, so the path is kept short. Beyond it the
/// oldest view is let go; its timeline entries still reopen by address.
@MainActor
struct DisplacedPages {
    static let depth = 2

    private var back: [WKWebView] = []
    private var forward: [WKWebView] = []

    var canGoBack: Bool { !back.isEmpty }
    var canGoForward: Bool { !forward.isEmpty }

    /// A new page in front of `view`. Like any new navigation it ends the
    /// forward path.
    /// - Returns: the views no longer reachable, for the caller to release.
    mutating func displace(_ view: WKWebView) -> [WKWebView] {
        back.append(view)
        var released = clearForward()
        if back.count > Self.depth { released.append(back.removeFirst()) }
        return released
    }

    /// - Returns: the page before `current`, which becomes the next page forward.
    mutating func stepBack(leaving current: WKWebView) -> WKWebView? {
        guard let previous = back.popLast() else { return nil }
        forward.append(current)
        return previous
    }

    /// - Returns: the page after `current`, which becomes the next page back.
    mutating func stepForward(leaving current: WKWebView) -> WKWebView? {
        guard let next = forward.popLast() else { return nil }
        back.append(current)
        return next
    }

    mutating func clearForward() -> [WKWebView] {
        defer { forward.removeAll() }
        return forward
    }

    mutating func removeAll() -> [WKWebView] {
        defer { back.removeAll() }
        return back + clearForward()
    }
}
