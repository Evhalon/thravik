import Foundation

/// Translation and linear shrink share one clock and one frame, preserving the moving center.
public struct FloatingVideoRelease: Sendable {
    private let initial: CGRect
    private let restingSize: CGSize
    private let lift: CGFloat
    public static let duration = 0.24

    public init(frame: CGRect, restingSize: CGSize, lift: CGFloat) {
        initial = frame
        self.restingSize = restingSize
        self.lift = lift
    }

    public func progress(at elapsed: Double) -> CGFloat {
        elapsed.isFinite ? CGFloat(min(max(elapsed / Self.duration, 0), 1)) : 0
    }

    public func frame(at origin: CGPoint, elapsed: Double) -> CGRect {
        let progress = progress(at: elapsed)
        var result = CGRect()
        result.size = CGSize(width: initial.size.width + (restingSize.width - initial.size.width) * progress,
            height: initial.size.height + (restingSize.height - initial.size.height) * progress)
        result.origin = CGPoint(x: origin.x + (initial.size.width - result.size.width) / 2,
            y: origin.y + (initial.size.height - result.size.height) / 2 - lift * progress)
        return result
    }
}
