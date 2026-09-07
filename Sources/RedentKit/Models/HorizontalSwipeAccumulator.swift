import Foundation

/// Accumulates a trackpad/mouse horizontal swipe into a single page step.
public struct HorizontalSwipeAccumulator: Equatable, Sendable {
    public var threshold: Double
    private var pending: Double
    private var locked: Bool

    public init(threshold: Double = 80) {
        self.threshold = threshold
        self.pending = 0
        self.locked = false
    }

    /// `1` is next (swipe left), `-1` is previous (swipe right).
    public mutating func add(deltaX: Double, deltaY: Double) -> Int? {
        guard !locked, abs(deltaX) > abs(deltaY) else { return nil }
        pending += deltaX
        if pending <= -threshold { return lockStep(1) }
        if pending >= threshold { return lockStep(-1) }
        return nil
    }

    public mutating func endGesture() {
        pending = 0
        locked = false
    }

    private mutating func lockStep(_ step: Int) -> Int {
        locked = true
        pending = 0
        return step
    }
}
