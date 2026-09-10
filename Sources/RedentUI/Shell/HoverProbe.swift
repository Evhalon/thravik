import AppKit
import SwiftUI

/// Reports the pointer entering and leaving a band, without taking a single
/// click from whatever is underneath it.
///
/// SwiftUI's `.onHover` cannot do this over a web view: a SwiftUI strip has to
/// be hit-testable to report hover, which steals clicks from the page. A
/// tracking area is notified from geometry alone, so this view sits on top of
/// the page, refuses every hit test, and still knows the pointer is there.
struct HoverProbe: NSViewRepresentable {
    let onChange: (Bool) -> Void

    func makeNSView(context: Context) -> NSView {
        ProbeView(onChange: onChange)
    }

    func updateNSView(_ view: NSView, context: Context) {
        guard let probe = view as? ProbeView else { return }
        probe.onChange = onChange
    }
}

private final class ProbeView: NSView {
    var onChange: (Bool) -> Void
    private var isInside = false

    init(onChange: @escaping (Bool) -> Void) {
        self.onChange = onChange
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    /// Invisible to the mouse: the page keeps every click, selection and drag.
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeInActiveApp, .inVisibleRect],
            owner: self
        ))
        // The pointer can already be inside a band that just appeared, or be
        // left outside one that moved out from under it, and neither case sends
        // an enter or exit event.
        resync()
    }

    override func mouseEntered(with event: NSEvent) { report(true) }

    override func mouseExited(with event: NSEvent) { report(false) }

    private func resync() {
        guard let window else { return report(false) }
        let point = convert(window.mouseLocationOutsideOfEventStream, from: nil)
        report(bounds.contains(point))
    }

    private func report(_ inside: Bool) {
        guard inside != isInside else { return }
        isInside = inside
        onChange(inside)
    }
}
