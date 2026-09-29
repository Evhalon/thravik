import AppKit

@MainActor
final class FloatingVideoInteraction {
    private static let trackpadGain: CGFloat = 2.1
    private let motion = FloatingVideoDrag()
    private let pickup = FloatingVideoPickup()
    private let feedback: FloatingVideoFeedback
    private weak var activeWindow: NSWindow?
    private var scrollMonitor: Any?
    private var deactivationObserver: NSObjectProtocol?
    private var pointerCaptured = false
    private var pointerAnchor = CGPoint(x: 0.5, y: 0.5)
    private var touching = false
    private var trackpadHeld = false
    private(set) var isHeld = false

    init(feedback: FloatingVideoFeedback = .system) { self.feedback = feedback }

    func touches(_ count: Int) {
        touching = count >= 2
        if !touching, isHeld, trackpadHeld, let activeWindow { finish(activeWindow) }
    }

    func scroll(_ event: NSEvent, in window: NSWindow) {
        guard event.hasPreciseScrollingDeltas, event.momentumPhase.isEmpty else { return }
        guard !isHeld || trackpadHeld else { return }
        if event.phase.contains(.cancelled) { finish(window, throwing: false); return }
        if event.phase.contains(.ended) {
            if !touching { finish(window) }
            return
        }
        guard event.phase.contains(.began) || event.phase.contains(.changed) else { return }
        if !isHeld { begin(window, at: event.timestamp) }
        let sign: CGFloat = event.isDirectionInvertedFromDevice ? 1 : -1
        move(window, delta: CGSize(width: event.scrollingDeltaX * sign * Self.trackpadGain,
            height: -event.scrollingDeltaY * sign * Self.trackpadGain), at: event.timestamp)
    }

    func begin(_ window: NSWindow, at timestamp: TimeInterval, trackpad: Bool = true) {
        guard !isHeld else { return }
        motion.begin(at: timestamp)
        activeWindow = window
        isHeld = true
        trackpadHeld = trackpad
        pickup.begin(window)
        feedback.pickup()
        if trackpad {
            window.makeFirstResponder(window.contentView)
            anchorPointer(in: window)
            pointerCaptured = feedback.capture()
            monitorScroll()
        }
        deactivationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in MainActor.assumeIsolated { self?.stop() } }
    }

    func move(_ window: NSWindow, delta: CGSize, at timestamp: TimeInterval) {
        guard isHeld else { return }
        motion.move(window, delta: delta, at: timestamp)
        followPointer(in: window)
    }

    func finish(_ window: NSWindow, throwing: Bool = true) {
        guard isHeld else { return }
        isHeld = false
        trackpadHeld = false
        cleanupCapture()
        pickup.finish(window)
        motion.finish(window, throwing: throwing) { [weak pickup] window, origin, elapsed in
            pickup?.place(window, at: origin, elapsed: elapsed)
        }
    }

    func stop() {
        isHeld = false
        trackpadHeld = false
        touching = false
        cleanupCapture()
        motion.cancel()
        pickup.cancel(activeWindow)
        activeWindow = nil
    }

    private func monitorScroll() {
        scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel, .gesture]) { [weak self] event in
            guard let self, self.isHeld, let window = self.activeWindow else { return event }
            if event.type == .scrollWheel { self.scroll(event, in: window); return nil }
            self.touches(event.touches(matching: .touching, in: nil).count)
            return event
        }
    }

    private func cleanupCapture() {
        if let scrollMonitor { NSEvent.removeMonitor(scrollMonitor) }
        scrollMonitor = nil
        if let deactivationObserver { NotificationCenter.default.removeObserver(deactivationObserver) }
        deactivationObserver = nil
        if pointerCaptured { feedback.release() }
        pointerCaptured = false
    }

    private func anchorPointer(in window: NSWindow) {
        let location = NSEvent.mouseLocation
        guard window.frame.contains(location) else { pointerAnchor = CGPoint(x: 0.5, y: 0.5); return }
        pointerAnchor = CGPoint(x: (location.x - window.frame.minX) / window.frame.width,
            y: (location.y - window.frame.minY) / window.frame.height)
    }

    private func followPointer(in window: NSWindow) {
        guard pointerCaptured else { return }
        feedback.follow(CGPoint(x: window.frame.minX + window.frame.width * pointerAnchor.x,
            y: window.frame.minY + window.frame.height * pointerAnchor.y))
    }
}
