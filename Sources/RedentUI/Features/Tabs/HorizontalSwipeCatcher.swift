import AppKit
import RedentKit
import SwiftUI

/// What a sideways swipe over the sidebar asks of the Space pager.
struct SpaceSwipeHandlers {
    /// Every trackpad movement while the fingers are down.
    var onTravel: (SpaceSwipe) -> Void
    /// The fingers lifted: settle on a page.
    var onRelease: (SpaceSwipe) -> Void
    /// A mouse wheel has no fingers to follow, so it turns whole pages.
    var onStep: (Int) -> Void
}

/// Invisible overlay: two-finger trackpad and mouse horizontal scroll drive
/// the Space pager. Clicks pass through via `allowsHitTesting(false)` on the
/// caller; this view listens with a local event monitor instead.
struct HorizontalSwipeCatcher: NSViewRepresentable {
    var handlers: SpaceSwipeHandlers

    func makeNSView(context: Context) -> NSView {
        let view = Host()
        view.handlers = handlers
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        (view as? Host)?.handlers = handlers
    }
}

/// `NSView` helper for `HorizontalSwipeCatcher`. Listens in `scrollWheel`
/// space via a local monitor so SwiftUI hit-testing does not swallow it.
private final class Host: NSView {
    var handlers = SpaceSwipeHandlers(onTravel: { _ in }, onRelease: { _ in }, onStep: { _ in })
    private var swipe: SpaceSwipe?
    /// The momentum after a claimed swipe belongs to it too; the tab list
    /// underneath must not coast on it.
    private var ownsMomentum = false
    private var wheel = HorizontalSwipeAccumulator()
    private var monitor: Any?
    private var lastStep: TimeInterval = 0

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        tearDownMonitor()
        guard window != nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            self?.handle(event) ?? event
        }
    }

    override func removeFromSuperview() {
        tearDownMonitor()
        super.removeFromSuperview()
    }

    func handle(_ event: NSEvent) -> NSEvent? {
        guard event.window === window else { return event }
        if !event.momentumPhase.isEmpty { return coast(event) }
        guard event.hasPreciseScrollingDeltas, !event.phase.isEmpty else { return turnWheel(event) }
        return track(event)
    }

    private func track(_ event: NSEvent) -> NSEvent? {
        if event.phase.contains(.began) {
            swipe = containsCursor(event) ? SpaceSwipe() : nil
            ownsMomentum = false
        }
        guard var current = swipe else { return event }
        if event.phase.contains(.ended) || event.phase.contains(.cancelled) {
            swipe = nil
            guard current.axis == .horizontal else { return event }
            ownsMomentum = true
            handlers.onRelease(current)
            return nil
        }
        let claimed = current.add(deltaX: Double(event.scrollingDeltaX), deltaY: Double(event.scrollingDeltaY))
        swipe = current
        guard claimed else { return event }
        handlers.onTravel(current)
        return nil
    }

    private func coast(_ event: NSEvent) -> NSEvent? {
        guard ownsMomentum else { return event }
        if event.momentumPhase.contains(.ended) || event.momentumPhase.contains(.cancelled) {
            ownsMomentum = false
        }
        return nil
    }

    private func turnWheel(_ event: NSEvent) -> NSEvent? {
        guard containsCursor(event) else { return event }
        let scale = event.hasPreciseScrollingDeltas ? 1 : wheel.threshold
        let deltaX = Double(event.scrollingDeltaX) * scale
        let deltaY = Double(event.scrollingDeltaY) * scale
        guard abs(deltaX) > abs(deltaY) else { return event }
        if let step = wheel.add(deltaX: deltaX, deltaY: deltaY) {
            emit(step)
            wheel.endGesture()
        }
        return nil
    }

    private func containsCursor(_ event: NSEvent) -> Bool {
        bounds.contains(convert(event.locationInWindow, from: nil))
    }

    private func emit(_ step: Int) {
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastStep >= 0.28 else { return }
        lastStep = now
        handlers.onStep(step)
    }

    private func tearDownMonitor() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        self.monitor = nil
    }
}
