import AppKit
import RedentKit
import SwiftUI

/// Invisible overlay: two-finger trackpad and mouse horizontal scroll
/// become page steps. Clicks pass through via `allowsHitTesting(false)`
/// on the caller; this view listens with a local event monitor instead.
struct HorizontalSwipeCatcher: NSViewRepresentable {
    var onStep: (Int) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = Host()
        view.onStep = onStep
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        (view as? Host)?.onStep = onStep
    }
}

/// `NSView` helper for `HorizontalSwipeCatcher`. Listens in `scrollWheel`
/// space via a local monitor so SwiftUI hit-testing does not swallow it.
private final class Host: NSView {
    var onStep: (Int) -> Void = { _ in }
    private var accumulator = HorizontalSwipeAccumulator()
    private var monitor: Any?
    private var lastFire: TimeInterval = 0

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
        guard event.window === window, containsCursor(event) else { return event }
        if event.phase.contains(.ended) || event.phase.contains(.cancelled)
            || event.momentumPhase.contains(.ended) {
            accumulator.endGesture()
            return event
        }
        if event.phase.contains(.began) { accumulator.endGesture() }
        let delta = scaledDelta(event)
        guard abs(delta.x) > abs(delta.y) else { return event }
        if let step = accumulator.add(deltaX: delta.x, deltaY: delta.y) {
            emit(step)
            if event.phase.isEmpty, event.momentumPhase.isEmpty { accumulator.endGesture() }
        }
        return nil
    }

    private func containsCursor(_ event: NSEvent) -> Bool {
        bounds.contains(convert(event.locationInWindow, from: nil))
    }

    private func scaledDelta(_ event: NSEvent) -> (x: Double, y: Double) {
        let x = Double(event.scrollingDeltaX)
        let y = Double(event.scrollingDeltaY)
        guard event.hasPreciseScrollingDeltas else {
            return (x * accumulator.threshold, y * accumulator.threshold)
        }
        return (x, y)
    }

    private func emit(_ step: Int) {
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastFire >= 0.28 else { return }
        lastFire = now
        onStep(step)
    }

    private func tearDownMonitor() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        self.monitor = nil
    }
}
