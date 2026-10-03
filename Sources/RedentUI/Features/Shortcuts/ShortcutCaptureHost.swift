import AppKit
import SwiftUI

/// Local keyDown monitor that lives only while a row is recording.
struct ShortcutCaptureHost: NSViewRepresentable {
    let onEvent: (NSEvent) -> Void

    func makeNSView(context: Context) -> ShortcutCaptureView {
        let view = ShortcutCaptureView()
        view.onEvent = onEvent
        return view
    }

    func updateNSView(_ view: ShortcutCaptureView, context: Context) {
        view.onEvent = onEvent
    }
}
