import AppKit
import WebKit

/// Find-in-page, hard reload, and printing: the page-level commands every
/// browser is expected to have, expressed against the live web view.
extension WebTab {
    /// Highlights the next match, wrapping at the end the way ⌘G does
    /// everywhere else.
    public func findInPage(_ query: String, forward: Bool) async -> Bool {
        guard let webView, !query.isEmpty else { return false }
        let configuration = WKFindConfiguration()
        configuration.backwards = !forward
        configuration.caseSensitive = false
        configuration.wraps = true
        // A find on a page that navigated out from under it throws rather than
        // reporting no match; either way the answer is the same.
        let result = try? await webView.find(query, configuration: configuration)
        return result?.matchFound ?? false
    }

    /// Runs in the isolated `redent` world, which shares the document with the
    /// page but not its scripts (AGENTS.md §5). The selection it clears is the
    /// one WebKit's own find left behind.
    public func clearFindHighlight() {
        guard let webView else { return }
        webView.evaluateJavaScript(
            "window.getSelection().removeAllRanges();",
            in: nil,
            in: PageScripts.contentWorld
        ) { _ in }
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
