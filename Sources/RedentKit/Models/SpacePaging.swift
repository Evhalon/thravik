import Foundation

/// Next/previous Space for swipe and page-dot navigation. Does not wrap.
public enum SpacePaging: Sendable {
    public static func neighbor(of selected: UUID?, in ids: [UUID], step: Int) -> UUID? {
        guard !ids.isEmpty else { return nil }
        guard let selected, let index = ids.firstIndex(of: selected) else { return ids.first }
        let next = index + step
        guard ids.indices.contains(next) else { return nil }
        return ids[next]
    }
}
