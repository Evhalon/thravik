import WebKit

/// The web view every tab uses. It differs from WebKit's in one place: the
/// page's own "Inspect Element" opens Chrome's DevTools instead of Safari's
/// Web Inspector, when the tab has somewhere to send that request.
final class BrowserWebView: WKWebView {
    /// Set by the tab that shows this view; nil leaves WebKit's inspector.
    /// Receives the right-clicked point in the page's CSS pixels.
    var onInspectElement: ((CGPoint) -> Void)?

    private static let inspectElement = NSUserInterfaceItemIdentifier("WKMenuItemIdentifierInspectElement")

    /// WebKit's item is replaced, not retargeted: its menu target still acts
    /// on an item it recognises, and then brings Safari's Web Inspector up
    /// alongside Chrome's.
    override func willOpenMenu(_ menu: NSMenu, with event: NSEvent) {
        super.willOpenMenu(menu, with: event)
        guard onInspectElement != nil,
              let index = menu.items.firstIndex(where: { $0.identifier == Self.inspectElement })
        else { return }
        let item = NSMenuItem(title: menu.items[index].title, action: #selector(inspectInChrome(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = NSValue(point: pagePoint(of: event))
        menu.removeItem(at: index)
        menu.insertItem(item, at: index)
    }

    @objc private func inspectInChrome(_ sender: NSMenuItem) {
        guard let point = (sender.representedObject as? NSValue)?.pointValue else { return }
        onInspectElement?(point)
    }

    /// Where the event happened, in the coordinates `elementFromPoint` takes.
    private func pagePoint(of event: NSEvent) -> CGPoint {
        let local = convert(event.locationInWindow, from: nil)
        let scale = max(pageZoom * magnification, 0.01)
        let top = isFlipped ? local.y : bounds.height - local.y
        return CGPoint(x: local.x / scale, y: top / scale)
    }
}
