import Foundation

/// Quadratic arc from the page toward the downloads button.
public enum DownloadArrivalPath: Sendable {
    public static let duration: TimeInterval = 0.56
    public static let reducedDuration: TimeInterval = 0.28

    public static func point(progress: Double, from start: CGPoint, to end: CGPoint) -> CGPoint {
        let t = clamped(progress)
        let span = max(abs(end.x - start.x), abs(end.y - start.y), 48)
        let control = CGPoint(x: (start.x + end.x) / 2, y: min(start.y, end.y) - span * 0.38)
        let u = 1 - t
        return CGPoint(
            x: u * u * start.x + 2 * u * t * control.x + t * t * end.x,
            y: u * u * start.y + 2 * u * t * control.y + t * t * end.y
        )
    }

    public static func scale(progress: Double) -> Double {
        1 - 0.48 * clamped(progress)
    }

    public static func clamped(_ progress: Double) -> Double {
        guard progress.isFinite else { return 0 }
        return min(max(progress, 0), 1)
    }
}
