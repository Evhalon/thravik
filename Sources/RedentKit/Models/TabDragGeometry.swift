import Foundation

/// Slot and live-shift math for dragging a tab along a strip.
///
/// `slot` is how many *other* tabs sit before the pointer, so a drag never
/// has to hit a row's exact frame — crossing a midpoint is enough.
public enum TabDragGeometry: Sendable {
    public static func slot(pointer: CGFloat, mids: [(UUID, CGFloat)], lifted: UUID) -> Int {
        mids.filter { $0.0 != lifted && $0.1 < pointer }.count
    }

    /// Other rows slide by `span` to open a gap at `slot` and close the hole
    /// the lifted tab left. Indices are the frozen visual order, including
    /// the lifted tab.
    public static func shifts(
        ids: [UUID],
        lifted: UUID,
        from: Int,
        slot: Int,
        span: CGFloat
    ) -> [UUID: CGFloat] {
        var result: [UUID: CGFloat] = [:]
        for (index, id) in ids.enumerated() where id != lifted {
            if from < index && index <= slot { result[id] = -span }
            else if slot <= index && index < from { result[id] = span }
        }
        return result
    }
}
