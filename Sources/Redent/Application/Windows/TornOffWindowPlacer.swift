import AppKit
import SwiftUI

/// Moves a torn-off tab's window to where the tab was let go, then fades it in.
///
/// The window stays transparent until it is in place: SwiftUI positions a new
/// window itself after attaching it, so the frame is applied again once that
/// has happened, and the default spot never flashes on screen.
struct TornOffWindowPlacer: NSViewRepresentable {
    let frame: CGRect

    func makeNSView(context: Context) -> NSView { Host(target: frame) }

    func updateNSView(_ view: NSView, context: Context) {}
}

private final class Host: NSView {
    private let target: CGRect
    private var placed = false

    init(target: CGRect) {
        self.target = target
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window, !placed else { return }
        placed = true
        window.alphaValue = 0
        place(window)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(60)) { [weak self, weak window] in
            guard let self, let window else { return }
            self.place(window)
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                window.animator().alphaValue = 1
            }
        }
    }

    private func place(_ window: NSWindow) {
        let screen = NSScreen.screens.first { $0.frame.intersects(target) } ?? window.screen
        window.setFrame(window.constrainFrameRect(target, to: screen), display: true)
    }
}
