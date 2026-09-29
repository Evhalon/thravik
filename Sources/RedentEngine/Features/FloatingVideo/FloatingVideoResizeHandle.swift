import AppKit
import RedentKit

@MainActor
final class FloatingVideoResizeHandle: NSView {
    var onBegin: (() -> Void)?
    private var resizing: FloatingVideoResize?
    private var initialPointer = CGPoint.zero

    init() {
        super.init(frame: .zero)
        setAccessibilityLabel("Resize video")
        setAccessibilityHelp("Drag this corner to resize the video.")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .frameResize(position: .bottomRight, directions: .all))
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.white.withAlphaComponent(0.75).setStroke()
        let path = NSBezierPath()
        path.lineWidth = 1.5
        path.lineCapStyle = .round
        for offset in [CGFloat(0), 5] {
            path.move(to: CGPoint(x: bounds.maxX - 10 - offset, y: 8))
            path.line(to: CGPoint(x: bounds.maxX - 8, y: 10 + offset))
        }
        path.stroke()
    }

    override func mouseDown(with event: NSEvent) {
        guard let window else { return }
        onBegin?()
        window.makeFirstResponder(superview)
        initialPointer = window.convertPoint(toScreen: event.locationInWindow)
        let desktop = FloatingVideoDesktop(screens: NSScreen.screens.map(\.visibleFrame))
        resizing = FloatingVideoResize(frame: window.frame,
            screen: desktop.screen(for: window.frame) ?? window.frame)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window, let resizing else { return }
        let point = window.convertPoint(toScreen: event.locationInWindow)
        let frame = resizing.frame(delta: CGSize(width: point.x - initialPointer.x,
                                                 height: point.y - initialPointer.y))
        window.setFrame(frame, display: true)
    }

    override func mouseUp(with event: NSEvent) { resizing = nil }
}
