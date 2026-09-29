import AppKit

@MainActor
final class FloatingVideoSurface: NSView {
    let host: WebViewHost
    private let interaction = FloatingVideoInteraction()
    private let resizeHandle = FloatingVideoResizeHandle()
    private var controls: NSView?
    private var hoverTracking: NSTrackingArea?
    private var isTransitioning = false

    init(host: WebViewHost) {
        self.host = host
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 16
        layer?.masksToBounds = true
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.white.withAlphaComponent(0.16).cgColor
        allowedTouchTypes = [.indirect]
        wantsRestingTouches = true
        resizeHandle.onBegin = { [weak self] in self?.interaction.stop() }
        addSubview(resizeHandle)
        setAccessibilityLabel("Floating video. Drag or swipe with two fingers to move.")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override var acceptsFirstResponder: Bool { true }

    func attachHost() {
        host.isHidden = false
        addSubview(host)
        addSubview(resizeHandle, positioned: .above, relativeTo: host)
        host.frame = bounds
    }

    func installControls(_ controls: NSView) {
        self.controls = controls
        addSubview(controls)
        controls.alphaValue = 0
        layout()
    }

    override func layout() {
        super.layout()
        host.frame = bounds
        let width = min(360, max(0, bounds.width - 24))
        controls?.frame = NSRect(x: (bounds.width - width) / 2, y: 8, width: width, height: 104)
        resizeHandle.frame = NSRect(x: bounds.width - 32, y: 0, width: 32, height: 32)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let hoverTracking { removeTrackingArea(hoverTracking) }
        let tracking = NSTrackingArea(rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self)
        hoverTracking = tracking
        addTrackingArea(tracking)
    }

    override func mouseEntered(with event: NSEvent) {
        guard !isTransitioning else { return }
        controls?.animator().alphaValue = 1
    }
    override func mouseExited(with event: NSEvent) { controls?.animator().alphaValue = 0 }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard !isTransitioning else { return nil }
        let local = convert(point, from: superview)
        guard bounds.contains(local) else { return nil }
        if resizeHandle.frame.contains(local) { return super.hitTest(point) }
        if let controls, controls.alphaValue > 0.1, controls.frame.contains(local) {
            return super.hitTest(point)
        }
        return self
    }

    override func scrollWheel(with event: NSEvent) {
        guard !isTransitioning, let window else { return }
        interaction.scroll(event, in: window)
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        if let window { interaction.begin(window, at: event.timestamp, trackpad: false) }
    }
    override func mouseDragged(with event: NSEvent) {
        guard let window else { return }
        interaction.move(window, delta: CGSize(width: event.deltaX, height: -event.deltaY), at: event.timestamp)
    }
    override func mouseUp(with event: NSEvent) {
        if let window { interaction.finish(window) }
    }

    override func touchesBegan(with event: NSEvent) {
        interaction.touches(event.touches(matching: .touching, in: self).count)
    }
    override func touchesMoved(with event: NSEvent) {
        interaction.touches(event.touches(matching: .touching, in: self).count)
    }
    override func touchesEnded(with event: NSEvent) {
        interaction.touches(event.touches(matching: .touching, in: self).count)
    }
    override func touchesCancelled(with event: NSEvent) { interaction.touches(0) }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        if newWindow == nil { interaction.stop() }
        super.viewWillMove(toWindow: newWindow)
    }

    func stopMotion() { interaction.stop() }

    func setTransitioning(_ transitioning: Bool) {
        isTransitioning = transitioning
        if transitioning { interaction.stop(); controls?.alphaValue = 0 }
    }
}
