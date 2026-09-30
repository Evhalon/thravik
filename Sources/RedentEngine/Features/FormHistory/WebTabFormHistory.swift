import WebKit
import RedentKit

/// Native side of form history. Suggestions are drawn by the app, outside the
/// page; the page script only learns how many there are, to steer the arrow
/// keys, and the one value the user picks.
extension WebTab {
    public func showFormSuggestions(count: Int) {
        evaluateFormHistory("window.redentFormSuggestions && window.redentFormSuggestions(\(max(count, 0)));")
    }

    /// Fills the field the user was typing in. Never submits its form.
    public func fillFormField(_ value: String) {
        // JSON-encoded so a quote or backslash in the value cannot break out.
        guard let data = try? JSONEncoder().encode([value]), let args = String(data: data, encoding: .utf8)
        else { return }
        evaluateFormHistory("window.redentFillFormField && window.redentFillFormField.apply(null, \(args));")
    }

    /// Where a rect in the page's CSS pixels sits on screen, following page
    /// zoom and pinch magnification the way `BrowserWebView` reads clicks.
    func screenRect(forPageRect rect: CGRect) -> CGRect? {
        guard let webView, let window = webView.window else { return nil }
        let scale = max(webView.pageZoom * webView.magnification, 0.01)
        var local = CGRect(x: rect.minX * scale, y: rect.minY * scale,
                           width: rect.width * scale, height: rect.height * scale)
        if !webView.isFlipped { local.origin.y = webView.bounds.height - local.maxY }
        return window.convertToScreen(webView.convert(local, to: nil))
    }

    private func evaluateFormHistory(_ source: String) {
        webView?.evaluateJavaScript("(function(){try{\(source)}catch(e){}})();", in: nil, in: PageScripts.contentWorld) { _ in }
    }
}
