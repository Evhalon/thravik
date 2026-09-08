import Foundation

/// Callbacks for one tab row, in either strip. Nested so each row view stays
/// one primary type. Optional members mean "not available for this row" —
/// their menu items disappear rather than sitting there disabled.
struct TabRowActions {
    let onSelect: () -> Void
    let onClose: () -> Void
    let onTogglePin: () -> Void
    var onCloseOthers: (() -> Void)?
    var onUngroup: (() -> Void)?
    /// This row's tab was dragged onto the tab with the given id. Nil for
    /// rows that cannot reorder.
    var onMoveOnto: ((UUID) -> Void)?
}
