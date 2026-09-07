import AppKit
import WebKit

/// Renders `alert()`, `confirm()` and `prompt()` as real sheets.
///
/// Silently dismissing them, which is the easy path, breaks any page that gates
/// a flow behind a confirm — the page waits forever for an answer it can't get.
@MainActor
enum JavaScriptPanelPresenter {
    static func alert(message: String, on webView: WKWebView) async {
        _ = await run(message: message, on: webView, buttons: ["OK"], field: nil)
    }

    static func confirm(message: String, on webView: WKWebView) async -> Bool {
        await run(message: message, on: webView, buttons: ["OK", "Cancel"], field: nil) != nil
    }

    static func prompt(message: String, defaultText: String?, on webView: WKWebView) async -> String? {
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 22))
        field.stringValue = defaultText ?? ""
        return await run(message: message, on: webView, buttons: ["OK", "Cancel"], field: field)
            .map { _ in field.stringValue }
    }

    /// - Returns: `nil` when the user cancels, otherwise the confirming response.
    private static func run(
        message: String,
        on webView: WKWebView,
        buttons: [String],
        field: NSView?
    ) async -> NSApplication.ModalResponse? {
        let alert = NSAlert()
        alert.messageText = pageName(for: webView)
        alert.informativeText = message
        alert.accessoryView = field
        for title in buttons { alert.addButton(withTitle: title) }

        let response: NSApplication.ModalResponse
        if let window = webView.window {
            response = await alert.beginSheetModal(for: window)
        } else {
            response = alert.runModal()
        }
        return response == .alertFirstButtonReturn ? response : nil
    }

    /// Pages can put anything in an alert, so the title says who is asking.
    private static func pageName(for webView: WKWebView) -> String {
        guard let host = webView.url?.host() else { return "This page says" }
        return "\(host) says"
    }
}
