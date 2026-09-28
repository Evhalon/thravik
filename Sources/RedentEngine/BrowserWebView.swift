import WebKit

/// The web view every tab uses. It differs from WebKit's in one place: the
/// page's own "Inspect Element" opens Chrome's DevTools instead of Safari's
/// Web Inspector, when the tab has somewhere to send that request.
final class BrowserWebView: WKWebView {
    /// Set by the tab that shows this view; nil leaves WebKit's inspector.
    var onInspectElement: (() -> Void)?

    private static let inspectElement = NSUserInterfaceItemIdentifier("WKMenuItemIdentifierInspectElement")

    override func willOpenMenu(_ menu: NSMenu, with event: NSEvent) {
        super.willOpenMenu(menu, with: event)
        guard onInspectElement != nil,
              let item = menu.items.first(where: { $0.identifier == Self.inspectElement })
        else { return }
        item.target = self
        item.action = #selector(inspectInChrome(_:))
    }

    @objc private func inspectInChrome(_ sender: Any?) {
        onInspectElement?()
    }
}
