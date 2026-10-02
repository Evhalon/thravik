import AppKit
import RedentKit
import WebKit

extension WebTab {
    public func findInPage(_ query: String, forward: Bool) async -> FindMatches {
        guard let webView else { return .empty }
        return await pageFinder.search(query, forward: forward, in: webView)
    }

    public func clearFindHighlight() {
        guard let webView else { return }
        pageFinder.clear(in: webView)
    }

    public func focusPage() {
        guard let webView else { return }
        webView.window?.makeFirstResponder(webView)
    }

    public func selectedPageText() async -> String? {
        guard let webView else { return nil }
        let text = try? await webView.callAsyncJavaScript(
            """
            const field = document.activeElement;
            if (field && /^(INPUT|TEXTAREA)$/.test(field.nodeName) && field.type !== 'password') {
                const start = field.selectionStart, end = field.selectionEnd;
                if (start !== null && end > start) return field.value.slice(start, end).slice(0, 1000);
            }
            return String(window.getSelection() || '').slice(0, 1000);
            """,
            in: nil, contentWorld: PageScripts.contentWorld
        ) as? String
        return text?.isEmpty == false ? text : nil
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
