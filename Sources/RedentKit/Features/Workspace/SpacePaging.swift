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

    /// Which pages the pager draws, as sides of the one in view: `-1` just
    /// left, `0` in view, `1` just right. With only two Spaces the other one is
    /// both neighbours at once, so `lean` — `1` or `-1` — picks its side.
    public static func sides(count: Int, lean: Int) -> [Int] {
        switch count {
        case ...0: []
        case 1: [0]
        case 2: [0, lean < 0 ? -1 : 1]
        default: [-1, 0, 1]
        }
    }

    /// The pager counts pages without wrapping, so crossing the loop's seam
    /// moves the row one page on instead of flinging it back across every
    /// Space. This is the page nearest `page` that shows Space `index`; with
    /// two Spaces both ways are one page and `lean` breaks the tie.
    public static func nearestPage(showing index: Int, from page: Int, count: Int, lean: Int) -> Int {
        guard count > 0 else { return page }
        let ahead = wrapped(index - page, count: count)
        let behind = ahead - count
        if ahead == 0 { return page }
        if ahead != -behind { return ahead < -behind ? page + ahead : page + behind }
        return lean < 0 ? page + behind : page + ahead
    }

    /// The Space shown on an unwrapped page.
    public static func index(ofPage page: Int, count: Int) -> Int {
        count > 0 ? wrapped(page, count: count) : 0
    }

    private static func wrapped(_ index: Int, count: Int) -> Int {
        ((index % count) + count) % count
    }
}
