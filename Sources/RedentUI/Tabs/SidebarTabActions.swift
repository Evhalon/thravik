import RedentKit

/// Callbacks for one sidebar row. Nested so the row stays one primary type.
struct SidebarTabActions {
    let onSelect: () -> Void
    let onClose: () -> Void
    let onTogglePin: () -> Void
    var onUngroup: (() -> Void)?
}
