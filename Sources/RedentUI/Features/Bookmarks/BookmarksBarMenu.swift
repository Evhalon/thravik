import RedentKit
import SwiftUI

/// Shared item menu: page actions for a bookmark, then delete.
struct BookmarksBarMenu: View {
    let showsPageActions: Bool
    let onOpenNewTab: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    init(bookmark: Bookmark, callbacks: BookmarksBarCallbacks) {
        showsPageActions = true
        onOpenNewTab = { callbacks.onOpenNewTab(bookmark.url) }
        onEdit = { callbacks.onEdit(bookmark) }
        onDelete = { callbacks.onDelete(bookmark) }
    }

    init(folder: BookmarkFolder, callbacks: BookmarksBarCallbacks) {
        showsPageActions = false
        onOpenNewTab = {}
        onEdit = {}
        onDelete = { callbacks.onDeleteFolder(folder) }
    }

    var body: some View {
        if showsPageActions {
            Button("Open in New Tab", action: onOpenNewTab)
            Button("Edit…", action: onEdit)
        }
        Button(showsPageActions ? "Delete" : "Delete Folder…", role: .destructive, action: onDelete)
    }
}
