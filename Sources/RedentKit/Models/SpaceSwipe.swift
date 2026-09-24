import Foundation

/// One two-finger trackpad swipe across the Space pager: the page follows the
/// fingers, then settles on a neighbour or springs back.
///
/// The first few points of motion decide the axis for the whole gesture, so a
/// vertical scroll of the tab list never drifts sideways into the next Space.
public struct SpaceSwipe: Equatable, Sendable {
    public enum Axis: Equatable, Sendable { case undecided, horizontal, vertical }

    /// Past this share of the page width, letting go turns the page.
    static let commitFraction = 0.3
    /// A last movement this fast turns the page however short the swipe was.
    static let flickSpeed = 14.0
    /// Motion below this does not yet say which way the fingers are going.
    private static let axisSlop = 3.0
    /// Past the first or last Space the page moves this fraction of the fingers.
    private static let edgeResistance = 0.25

    public private(set) var axis: Axis = .undecided
    /// Raw finger travel; negative is towards the next Space.
    public private(set) var travel: Double = 0
    private var lastDelta: Double = 0
    private var pendingX: Double = 0
    private var pendingY: Double = 0

    public init() {}

    /// Adds one event's motion. `true` when the swipe owns it, so the list
    /// underneath must not scroll with it too.
    public mutating func add(deltaX: Double, deltaY: Double) -> Bool {
        if axis == .undecided { decideAxis(deltaX: deltaX, deltaY: deltaY) }
        guard axis == .horizontal else { return false }
        travel += deltaX
        lastDelta = deltaX
        return true
    }

    /// Where the pager draws the page: resisting past the ends of the row.
    public func offset(hasPrevious: Bool, hasNext: Bool) -> Double {
        let blocked = (travel > 0 && !hasPrevious) || (travel < 0 && !hasNext)
        return blocked ? travel * Self.edgeResistance : travel
    }

    /// `1` settles on the next Space, `-1` on the previous one, `0` springs back.
    public func settle(pageWidth: Double, hasPrevious: Bool, hasNext: Bool) -> Int {
        guard axis == .horizontal, pageWidth > 0 else { return 0 }
        let far = abs(travel) >= pageWidth * Self.commitFraction
        let flicked = abs(lastDelta) >= Self.flickSpeed && lastDelta.sign == travel.sign
        guard far || flicked else { return 0 }
        if travel < 0 { return hasNext ? 1 : 0 }
        return hasPrevious ? -1 : 0
    }

    private mutating func decideAxis(deltaX: Double, deltaY: Double) {
        pendingX += deltaX
        pendingY += deltaY
        guard abs(pendingX) + abs(pendingY) >= Self.axisSlop else { return }
        axis = abs(pendingX) > abs(pendingY) ? .horizontal : .vertical
        if axis == .horizontal { travel = pendingX - deltaX }
    }
}
