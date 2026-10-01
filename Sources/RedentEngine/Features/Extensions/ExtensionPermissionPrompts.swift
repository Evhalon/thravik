import AppKit
import WebKit

/// `chrome.permissions.request`: an extension asking, while running, for more
/// than it was installed with. The user answers every such request; nothing
/// is granted silently.
extension ExtensionControllerDelegate {
    func webExtensionController(
        _ controller: WKWebExtensionController,
        promptForPermissions permissions: Set<WKWebExtension.Permission>,
        in tab: (any WKWebExtensionTab)?,
        for extensionContext: WKWebExtensionContext,
        completionHandler: @escaping (Set<WKWebExtension.Permission>, Date?) -> Void
    ) {
        let allowed = Self.ask(extensionContext, for: permissions.map(\.rawValue).sorted())
        completionHandler(allowed ? permissions : [], nil)
    }

    func webExtensionController(
        _ controller: WKWebExtensionController,
        promptForPermissionToAccess urls: Set<URL>,
        in tab: (any WKWebExtensionTab)?,
        for extensionContext: WKWebExtensionContext,
        completionHandler: @escaping (Set<URL>, Date?) -> Void
    ) {
        let hosts = Set(urls.compactMap { $0.host() }).sorted()
        let allowed = Self.ask(extensionContext, for: hosts.map { "Access \($0)" })
        completionHandler(allowed ? urls : [], nil)
    }

    func webExtensionController(
        _ controller: WKWebExtensionController,
        promptForPermissionMatchPatterns matchPatterns: Set<WKWebExtension.MatchPattern>,
        in tab: (any WKWebExtensionTab)?,
        for extensionContext: WKWebExtensionContext,
        completionHandler: @escaping (Set<WKWebExtension.MatchPattern>, Date?) -> Void
    ) {
        let allowed = Self.ask(extensionContext, for: matchPatterns.map(\.string).sorted())
        completionHandler(allowed ? matchPatterns : [], nil)
    }

    private static func ask(_ context: WKWebExtensionContext, for items: [String]) -> Bool {
        guard !items.isEmpty else { return true }
        let alert = NSAlert()
        let name = context.webExtension.displayName ?? "An extension"
        alert.messageText = "\(name) wants additional access"
        alert.informativeText = items.joined(separator: "\n")
        alert.addButton(withTitle: "Allow")
        alert.addButton(withTitle: "Deny")
        return alert.runModal() == .alertFirstButtonReturn
    }
}
