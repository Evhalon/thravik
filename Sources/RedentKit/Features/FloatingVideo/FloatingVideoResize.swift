import Foundation

/// A corner resize keeps the opposite corner anchored and the video proportional.
public struct FloatingVideoResize: Sendable {
    private let initial: CGRect
    private let screen: CGRect

    public init(frame: CGRect, screen: CGRect) {
        initial = frame
        self.screen = screen
    }

    public func frame(delta: CGSize) -> CGRect {
        let aspect = initial.size.width / max(initial.size.height, 1)
        let top = initial.origin.y + initial.size.height
        let availableWidth = screen.origin.x + screen.size.width - 12 - initial.origin.x
        let availableHeight = top - screen.origin.y - 12
        let maximum = max(1, min(availableWidth, availableHeight * aspect))
        let minimum = min(maximum, max(220, 124 * aspect))
        let horizontal = delta.width.isFinite ? delta.width : 0
        let vertical = delta.height.isFinite ? -delta.height * aspect : 0
        let change = abs(horizontal) >= abs(vertical) ? horizontal : vertical
        let width = min(max(initial.size.width + change, minimum), maximum)
        var result = CGRect()
        result.size = CGSize(width: width, height: width / aspect)
        result.origin = CGPoint(x: initial.origin.x, y: top - result.size.height)
        return result
    }
}
