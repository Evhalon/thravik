import Foundation

/// Display selection uses the player's geometry, independent of the cursor and AppKit's current screen.
public struct FloatingVideoDesktop: Sendable {
    private let screens: [CGRect]

    public init(screens: [CGRect]) {
        self.screens = screens.filter { screen in
            screen.origin.x.isFinite && screen.origin.y.isFinite
                && screen.size.width.isFinite && screen.size.height.isFinite
                && screen.size.width > 0 && screen.size.height > 0
        }
    }

    public func screen(for frame: CGRect) -> CGRect? {
        let center = CGPoint(x: frame.origin.x + frame.size.width / 2, y: frame.origin.y + frame.size.height / 2)
        if let containing = screens.first(where: { distance(center, to: $0) == 0 }) { return containing }
        return screens.min { distance(center, to: $0) < distance(center, to: $1) }
    }

    public func limits(for frame: CGRect) -> CGRect {
        var limits = CGRect()
        guard let screen = screen(for: frame) else {
            limits.origin = frame.origin
            return limits
        }
        limits.origin = CGPoint(x: screen.origin.x + 12, y: screen.origin.y + 12)
        limits.size = CGSize(width: max(0, screen.size.width - 24 - frame.size.width),
                             height: max(0, screen.size.height - 24 - frame.size.height))
        return limits
    }

    private func distance(_ point: CGPoint, to screen: CGRect) -> CGFloat {
        let horizontal = max(screen.origin.x - point.x, 0, point.x - (screen.origin.x + screen.size.width))
        let vertical = max(screen.origin.y - point.y, 0, point.y - (screen.origin.y + screen.size.height))
        return horizontal * horizontal + vertical * vertical
    }
}
