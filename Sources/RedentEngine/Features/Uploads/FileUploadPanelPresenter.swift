import AppKit
import WebKit

/// Shows the file chooser behind `<input type="file">`.
///
/// Without it WebKit treats every chooser as cancelled, so upload buttons
/// silently do nothing.
@MainActor
enum FileUploadPanelPresenter {
    /// - Returns: `nil` when the user cancels, which WebKit reports to the
    ///   page as an empty selection.
    static func chooseFiles(_ parameters: WKOpenPanelParameters, on webView: WKWebView) async -> [URL]? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = parameters.allowsDirectories
        panel.allowsMultipleSelection = parameters.allowsMultipleSelection
        panel.resolvesAliases = true
        panel.prompt = "Choose"
        if let host = webView.url?.host() { panel.message = "Choose files to upload to \(host)" }

        let response: NSApplication.ModalResponse
        if let window = webView.window {
            response = await panel.beginSheetModal(for: window)
        } else {
            response = panel.runModal()
        }
        return response == .OK ? panel.urls : nil
    }
}
