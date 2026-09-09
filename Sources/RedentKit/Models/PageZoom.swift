import Foundation

/// The ladder a page's zoom steps through.
///
/// Pure arithmetic on purpose: the menu commands, the tab that stores the level,
/// and the engine that applies it all agree on one set of rungs, and none of
/// them has to know what the others are.
public enum PageZoom {
    public static let identity: Double = 1

    /// Safari's rungs. A level arriving from an older saved workspace is snapped
    /// onto this ladder by the first step in either direction.
    public static let levels: [Double] = [0.5, 0.75, 0.85, 1, 1.15, 1.25, 1.5, 1.75, 2, 2.5, 3]

    public static var minimum: Double { levels.first ?? identity }
    public static var maximum: Double { levels.last ?? identity }

    public static func stepUp(from level: Double) -> Double {
        levels.first { $0 > level + tolerance } ?? maximum
    }

    public static func stepDown(from level: Double) -> Double {
        levels.last { $0 < level - tolerance } ?? minimum
    }

    public static func clamped(_ level: Double) -> Double {
        guard level.isFinite else { return identity }
        return min(max(level, minimum), maximum)
    }

    public static func isIdentity(_ level: Double) -> Bool {
        abs(level - identity) < tolerance
    }

    /// What the View menu shows next to "Actual Size".
    public static func label(_ level: Double) -> String {
        "\(Int((level * 100).rounded()))%"
    }

    /// Levels round-trip through JSON, so equality here is a neighbourhood.
    private static let tolerance = 0.0001
}
