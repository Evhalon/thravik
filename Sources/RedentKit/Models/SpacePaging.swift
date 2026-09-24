import Foundation

/// Next/previous Space for swipe and page-dot navigation. The row of Spaces is
/// a loop: past the last one comes the first again.
public enum SpacePaging: Sendable {
    public static func neighbor(of selected: UUID?, in ids: [UUID], step: Int) -> UUID? {
        guard !ids.isEmpty else { return nil }
        guard let selected, let index = ids.firstIndex(of: selected) else { return ids.first }
        guard ids.count > 1 else { return nil }
        return ids[wrapped(index + step, count: ids.count)]
    }

    /// Where the Space at `index` sits beside the current one: `-1` just left,
    /// `0` in view, `1` just right, `nil` when too far to draw. With only two
    /// Spaces the other one is both neighbours at once, so `lean` — the side
    /// the swipe is heading, `1` or `-1` — picks where it is drawn.
    public static func position(of index: Int, current: Int, count: Int, lean: Int) -> Int? {
        guard count > 0 else { return nil }
        let ahead = wrapped(index - current, count: count)
        if ahead == 0 { return 0 }
        if count == 2 { return lean < 0 ? -1 : 1 }
        if ahead == 1 { return 1 }
        return ahead == count - 1 ? -1 : nil
    }

    private static func wrapped(_ index: Int, count: Int) -> Int {
        ((index % count) + count) % count
    }
}
