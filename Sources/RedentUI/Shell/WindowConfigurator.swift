import AppKit
import SwiftUI

/// Reaches into the `NSWindow` for the two things SwiftUI cannot express.
///
/// The window must be non-opaque with a clear background, or AppKit paints an
/// opaque sheet behind the content and the behind-window blur has nothing to
/// sample — the glass comes out as flat grey.
struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let probe = NSView()
        DispatchQueue.main.async { configure(probe.window) }
        return probe
    }

    func updateNSView(_ view: NSView, context: Context) {
        configure(view.window)
    }

    /// Each assignment invalidates the whole window, and `updateNSView` runs on
    /// every SwiftUI update — during a live resize that is once a frame. So the
    /// window is only touched when it is not already how we want it.
    private func configure(_ window: NSWindow?) {
        guard let window else { return }
        if window.isOpaque { window.isOpaque = false }
        if window.backgroundColor != .clear { window.backgroundColor = .clear }
        if !window.titlebarAppearsTransparent { window.titlebarAppearsTransparent = true }
        if window.titleVisibility != .hidden { window.titleVisibility = .hidden }
        // Deliberately NOT movable by background: the chrome is full of drag
        // targets (the sidebar seam, tab reordering), and window-dragging
        // hijacks all of them. The titlebar strip still moves the window.
        if window.isMovableByWindowBackground { window.isMovableByWindowBackground = false }
        // A hidden titlebar can leave the window without the behaviour that
        // makes the green button and ⌃⌘F enter full screen rather than zoom,
        // and a page asking for element fullscreen needs a window that can.
        if !window.styleMask.contains(.resizable) { window.styleMask.insert(.resizable) }
        if !window.collectionBehavior.contains(.fullScreenPrimary) {
            window.collectionBehavior.insert(.fullScreenPrimary)
        }
    }
}
