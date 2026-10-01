import Foundation
import RedentKit

/// One cell of the pinned grid: a pinned tab, or the gap a dragged tab
/// would be pinned into.
struct PinnedCell: Identifiable {
    /// One id for the gap wherever it opens, so it slides between tiles
    /// rather than fading out at one cell and in at the next.
    private static let gapID = UUID()

    let id: UUID
    let tab: (any BrowserTab)?

    /// - Parameter gap: the cell to leave empty; past the end opens it last.
    @MainActor
    static func cells(_ tabs: [any BrowserTab], gap: Int?) -> [PinnedCell] {
        var cells = tabs.map { PinnedCell(id: $0.id, tab: $0) }
        if let gap {
            cells.insert(PinnedCell(id: gapID, tab: nil), at: min(max(gap, 0), cells.count))
        }
        return cells
    }

    /// The tiles with `tabID` lifted out and dropped back in at `slot`, where
    /// its empty cell is where a release would pin it.
    @MainActor
    static func cells(_ tabs: [any BrowserTab], moving tabID: UUID, to slot: Int) -> [PinnedCell] {
        guard let lifted = tabs.first(where: { $0.id == tabID }) else { return cells(tabs, gap: nil) }
        var cells = tabs.filter { $0.id != tabID }.map { PinnedCell(id: $0.id, tab: $0) }
        cells.insert(PinnedCell(id: tabID, tab: lifted), at: min(max(slot, 0), cells.count))
        return cells
    }
}
