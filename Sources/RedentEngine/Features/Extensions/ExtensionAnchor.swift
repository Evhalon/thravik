import AppKit
import SwiftUI

/// Remembers the AppKit view behind a SwiftUI control, so an extension's
/// popup can point at the button that opened it.
@MainActor
final class ExtensionAnchor {
    weak var view: NSView?
}

struct ExtensionAnchorReader: NSViewRepresentable {
    let anchor: ExtensionAnchor

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        anchor.view = view
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        anchor.view = nsView
    }
}
