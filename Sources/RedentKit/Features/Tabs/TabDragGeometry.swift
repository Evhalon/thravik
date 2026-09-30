import Foundation

/// Slot and live-shift math for dragging a tab along a strip.
///
/// `slot` is how many *other* rows sit before the pointer, so a drag never
/// has to hit a row's exact frame — crossing a midpoint is enough.
public enum TabDragGeometry: Sendable {
    public static func slot<Row: Hashable>(pointer: CGFloat, mids: [(Row, CGFloat)], lifted: Row) -> Int {
        mids.filter { $0.0 != lifted && $0.1 < pointer }.count
    }

    /// Other rows slide by `span` to open a gap at `slot` and close the hole
    /// the lifted tab left. Indices are the frozen visual order, including
    /// the lifted tab.
    public static func shifts<Row: Hashable>(
        ids: [Row],
        lifted: Row,
        from: Int,
        slot: Int,
        span: CGFloat
    ) -> [Row: CGFloat] {
        var result: [Row: CGFloat] = [:]
        for (index, id) in ids.enumerated() where id != lifted {
            if from < index && index <= slot { result[id] = -span }
            else if slot <= index && index < from { result[id] = span }
        }
        return result
    }
}
