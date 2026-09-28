import Foundation
import RedentKit

/// A pinned tile's callbacks: an ordinary tab's, plus what only a pin has.
/// Optional members mean "not available for this tile", as in `TabRowActions`.
struct PinnedTileActions {
    let row: TabRowActions
    /// Loads the pinned page again, once the tab has browsed away from it.
    var onReturn: (() -> Void)?
    /// Makes the page the tab shows now its pinned page.
    var onPinCurrentPage: (() -> Void)?
    var onCopyLink: (() -> Void)?
    /// Nil or blank restores the page's own title.
    let onRename: (String?) -> Void
    var moveTargets: [BrowserSpace] = []
    var onMove: (UUID) -> Void = { _ in }
}
