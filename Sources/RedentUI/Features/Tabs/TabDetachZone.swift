import AppKit

/// Decides whether a tab drag has left its window, and where the tab would land.
///
/// Read from AppKit because the drag gesture only reports points in the
/// strip's own coordinate space, which says nothing about the screen.
@MainActor
enum TabDetachZone {
    /// Past the window edge by this much, so a drag that merely overshoots
    /// the sidebar or tab strip still reorders instead of opening a window.
    private static let margin: CGFloat = 32
    /// Where the pointer holds the new window, from its top-left corner: about
    /// where a tab sits, so the tab stays under the pointer as it lands.
    private static let grip = CGPoint(x: 120, y: 44)

    static var pointer: CGPoint { NSEvent.mouseLocation }

    /// The frame a tab torn off right now would open in: its window's size,
    /// hanging from the pointer. Nil while the pointer is still over the window.
    static func landingFrame() -> CGRect? {
        guard let window = NSApp.keyWindow else { return nil }
        let pointer = self.pointer
        guard !window.frame.insetBy(dx: -margin, dy: -margin).contains(pointer) else { return nil }
        let size = window.frame.size
        let origin = CGPoint(x: pointer.x - grip.x, y: pointer.y + grip.y - size.height)
        return CGRect(origin: origin, size: size)
    }
}
