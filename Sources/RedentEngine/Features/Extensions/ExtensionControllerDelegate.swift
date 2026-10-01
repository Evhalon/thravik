import AppKit
import WebKit

/// Answers WebKit's questions about the browser on the host's behalf.
///
/// A separate object, weak to the host, because the controller holds its
/// delegate weakly and the host holds the controller strongly.
@MainActor
final class ExtensionControllerDelegate: NSObject, WKWebExtensionControllerDelegate {
    private weak var host: ExtensionHost?

    init(host: ExtensionHost) {
        self.host = host
    }

    func webExtensionController(
        _ controller: WKWebExtensionController, openWindowsFor extensionContext: WKWebExtensionContext
    ) -> [any WKWebExtensionWindow] {
        guard let host else { return [] }
        let focused = host.focusedWindow
        return (focused.map { [$0] } ?? []) + host.windows.filter { $0 !== focused }
    }

    func webExtensionController(
        _ controller: WKWebExtensionController, focusedWindowFor extensionContext: WKWebExtensionContext
    ) -> (any WKWebExtensionWindow)? {
        host?.focusedWindow
    }

    func webExtensionController(
        _ controller: WKWebExtensionController,
        openNewTabUsing configuration: WKWebExtension.TabConfiguration,
        for extensionContext: WKWebExtensionContext,
        completionHandler: @escaping ((any WKWebExtensionTab)?, (any Error)?) -> Void
    ) {
        let window = (configuration.window as? ExtensionWindow) ?? host?.focusedWindow
        completionHandler(host?.openTab(configuration.url, in: window, activate: configuration.shouldBeActive), nil)
    }

    /// Redent has no bare popup windows; the pages open as tabs in the
    /// focused window, which is where the user is looking anyway.
    func webExtensionController(
        _ controller: WKWebExtensionController,
        openNewWindowUsing configuration: WKWebExtension.WindowConfiguration,
        for extensionContext: WKWebExtensionContext,
        completionHandler: @escaping ((any WKWebExtensionWindow)?, (any Error)?) -> Void
    ) {
        let window = host?.focusedWindow
        for url in configuration.tabURLs { _ = host?.openTab(url, in: window, activate: true) }
        completionHandler(window, nil)
    }

    func webExtensionController(
        _ controller: WKWebExtensionController,
        openOptionsPageFor extensionContext: WKWebExtensionContext,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        host?.openOptions(of: extensionContext)
        completionHandler(nil)
    }

    func webExtensionController(
        _ controller: WKWebExtensionController,
        didUpdate action: WKWebExtension.Action,
        forExtensionContext context: WKWebExtensionContext
    ) {
        host?.changed()
    }

    func webExtensionController(
        _ controller: WKWebExtensionController,
        presentActionPopup action: WKWebExtension.Action,
        for context: WKWebExtensionContext,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        host?.presentPopup(of: action)
        completionHandler(nil)
    }
}
