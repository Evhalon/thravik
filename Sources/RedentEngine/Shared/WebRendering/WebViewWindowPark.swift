import AppKit

/// SwiftUI tears the host down on every tab or Space switch. Leaving a live
/// web view with no window lets WebKit kill its content process, so this
/// hidden sibling keeps the complete WebKit host in the browser window.
@MainActor
enum WebViewWindowPark {
    static let identifier = NSUserInterfaceItemIdentifier("redent.web-park")

    static func park(_ host: WebViewHost, from window: NSWindow?) {
        host.isHidden = true
        guard let window, let park = parkingHost(in: window) else {
            host.removeFromSuperview()
            return
        }
        if host.superview !== park { park.addSubview(host) }
    }

    private static func parkingHost(in window: NSWindow) -> NSView? {
        let parent = window.contentView?.superview ?? window.contentView
        if let existing = parent?.subviews.first(where: { $0.identifier == identifier }) {
            return existing
        }
        let park = NSView(frame: .zero)
        park.identifier = identifier
        park.isHidden = true
        parent?.addSubview(park)
        return park
    }
}
