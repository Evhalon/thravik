import Foundation

/// Screen-space motion with an injected clock; the native panel owns rendering.
public struct FloatingVideoMotion: Sendable {
    public let start: CGPoint
    public let velocity: CGSize
    public let target: CGPoint
    public let limits: CGRect
    public static let duration = 0.42

    public init(frame: CGRect, velocity: CGSize, screen: CGRect) {
        self.init(frame: frame, velocity: velocity, screens: [screen])
    }

    public init(frame: CGRect, velocity: CGSize, screens: [CGRect]) {
        start = frame.origin
        self.velocity = CGSize(width: Self.speed(velocity.width), height: Self.speed(velocity.height))
        var projected = frame
        projected.origin = CGPoint(
            x: start.x + self.velocity.width * Self.duration / 3,
            y: start.y + self.velocity.height * Self.duration / 3
        )
        limits = FloatingVideoDesktop(screens: screens).limits(for: projected)
        target = Self.clamp(projected.origin, to: limits)
    }

    public func position(at elapsed: Double) -> CGPoint {
        guard elapsed.isFinite, elapsed > 0 else { return start }
        guard elapsed < Self.duration else { return target }
        // An ease-out starts at the release velocity instead of stopping to accelerate again.
        let remaining = 1 - elapsed / Self.duration
        let progress = 1 - remaining * remaining * remaining
        return CGPoint(x: start.x + (target.x - start.x) * progress,
                       y: start.y + (target.y - start.y) * progress)
    }

    private static func speed(_ value: CGFloat) -> CGFloat {
        value.isFinite ? min(max(value, -5_000), 5_000) : 0
    }

    private static func clamp(_ point: CGPoint, to limits: CGRect) -> CGPoint {
        CGPoint(x: min(max(point.x, limits.origin.x), limits.origin.x + limits.size.width),
                y: min(max(point.y, limits.origin.y), limits.origin.y + limits.size.height))
    }
}
