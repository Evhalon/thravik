import Foundation
import RedentKit

/// Actions the bar chips share with overflow and context menus.
struct BookmarksBarCallbacks {
    let onOpen: (URL) -> Void
    let onOpenNewTab: (URL) -> Void
    let onEdit: (Bookmark) -> Void
    let onDelete: (Bookmark) -> Void
    let onDeleteFolder: (BookmarkFolder) -> Void
}
