import AppKit

/// Decides whether a tab drag ended far enough outside its window to tear off.
///
/// Read from AppKit at drop time because the drag gesture only reports points
/// in the strip's own coordinate space, which says nothing about the screen.
@MainActor
enum TabDetachZone {
    /// Past the window edge by this much, so a drag that merely overshoots
    /// the sidebar or tab strip still reorders instead of opening a window.
    private static let margin: CGFloat = 32

    static var pointerIsOutsideKeyWindow: Bool {
        guard let window = NSApp.keyWindow else { return false }
        let zone = window.frame.insetBy(dx: -margin, dy: -margin)
        return !zone.contains(NSEvent.mouseLocation)
    }
}
