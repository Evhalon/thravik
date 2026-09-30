import AppKit
import WebKit

/// Hands an app-scheme address to macOS after the user agrees.
///
/// Asking first matters: any page can navigate to `someapp://`, and launching
/// an app without consent would let a page drive other software.
@MainActor
enum ExternalAppLauncher {
    static func offer(_ url: URL, from webView: WKWebView) async {
        let alert = NSAlert()
        let page = webView.url?.host() ?? "This page"
        guard let appURL = NSWorkspace.shared.urlForApplication(toOpen: url) else {
            alert.messageText = "No app can open this link"
            alert.informativeText = "\(page) tried to open a “\(url.scheme ?? "")” link, "
                + "but no installed app handles it."
            alert.addButton(withTitle: "OK")
            _ = await present(alert, on: webView)
            return
        }
        let appName = FileManager.default.displayName(atPath: appURL.path)
            .replacingOccurrences(of: ".app", with: "")
        alert.messageText = "Open “\(appName)”?"
        alert.informativeText = "\(page) wants to open this link in \(appName)."
        alert.addButton(withTitle: "Open")
        alert.addButton(withTitle: "Cancel")
        guard await present(alert, on: webView) == .alertFirstButtonReturn else { return }
        NSWorkspace.shared.open(url)
    }

    private static func present(_ alert: NSAlert, on webView: WKWebView) async -> NSApplication.ModalResponse {
        guard let window = webView.window else { return alert.runModal() }
        return await alert.beginSheetModal(for: window)
    }
}
