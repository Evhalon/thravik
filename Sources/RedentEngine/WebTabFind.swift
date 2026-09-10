import AppKit
import RedentKit
import WebKit

/// Find-in-page, hard reload, and printing: the page-level commands every
/// browser is expected to have, expressed against the live web view.
extension WebTab {
    /// Paints every match the way the reader expects — the usual yellow, with
    /// the active one in orange — and steps to the next one.
    ///
    /// The search runs in `redent-find.js` rather than through WebKit's own
    /// `find`, which paints a match with the system selection colour and
    /// answers only "yes" or "no". A counter needs the total, and the page
    /// needs a colour a reader can actually pick out.
    public func findInPage(_ query: String, forward: Bool) async -> FindMatches {
        guard let webView, !query.isEmpty else { return .empty }
        // The call throws on a page that navigated out from under it; either
        // way the answer is that nothing is highlighted.
        let reply = try? await webView.callAsyncJavaScript(
            "return window.redentFind ? window.redentFind(query, forward) : null",
            arguments: ["query": query, "forward": forward],
            in: nil,
            contentWorld: PageScripts.contentWorld
        )
        return Self.matches(from: reply)
    }

    /// Runs in the isolated `redent` world, which shares the document with the
    /// page but not its scripts (AGENTS.md §5).
    public func clearFindHighlight() {
        guard let webView else { return }
        webView.evaluateJavaScript(
            "window.redentFindClear && window.redentFindClear();",
            in: nil,
            in: PageScripts.contentWorld
        ) { _ in }
    }

    /// A page that answers with anything but the expected pair — an old script,
    /// a frame that never loaded it — counts as no matches at all.
    private static func matches(from reply: Any?) -> FindMatches {
        guard let payload = reply as? [String: Any],
              let total = payload["total"] as? Int,
              let current = payload["current"] as? Int
        else { return .empty }
        return FindMatches(total: total, current: current)
    }

    public func reloadIgnoringCache() {
        guard let webView else { return reload() }
        BrowserUserAgent.apply(to: webView, for: webView.url ?? url)
        webView.reloadFromOrigin()
    }

    /// The page's own print operation, so headers and pagination come from
    /// WebKit rather than from a screenshot of the view.
    public func printPage() {
        guard let webView, let window = webView.window else { return }
        let info = NSPrintInfo.shared
        info.horizontalPagination = .fit
        info.verticalPagination = .automatic
        let operation = webView.printOperation(with: info)
        operation.view?.frame = webView.bounds
        operation.runModal(for: window, delegate: nil, didRun: nil, contextInfo: nil)
    }
}
