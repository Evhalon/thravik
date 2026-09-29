import AppKit
import SwiftUI

/// Empty chrome that still behaves like a titlebar: drag the window, or
/// double-click to zoom (or minimize, if the user asked the system for that).
///
/// `.hiddenTitleBar` plus `ignoresSafeArea` covers the real titlebar, and the
/// window is not movable by background — so this view is the strip that remains.
struct TitlebarDragRegion: NSViewRepresentable {
    enum Action: Equatable {
        case none, minimize, zoom
    }

    static func action(for defaultsValue: String?) -> Action {
        switch defaultsValue {
        case "None": .none
        case "Minimize": .minimize
        default: .zoom
        }
    }

    static func perform(on window: NSWindow?) {
        perform(
            on: window,
            action: action(for: UserDefaults.standard.string(forKey: "AppleActionOnDoubleClick"))
        )
    }

    static func perform(on window: NSWindow?, action: Action) {
        switch action {
        case .none: return
        case .minimize: window?.performMiniaturize(nil)
        case .zoom: window?.zoom(nil)
        }
    }

    func makeNSView(context: Context) -> NSView { TitlebarDragView() }
    func updateNSView(_ view: NSView, context: Context) {}
}

private final class TitlebarDragView: NSView {
    override var mouseDownCanMoveWindow: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        guard let window else { return }
        if event.clickCount >= 2 {
            TitlebarDragRegion.perform(on: window)
            return
        }
        window.performDrag(with: event)
    }
}
