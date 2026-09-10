import Foundation
import RedentKit

/// The bookmark star, and the ⌘D behind it.
///
/// The lookup lives on the window model rather than in the button, so the
/// keyboard shortcut and the toolbar control always show the same answer.
extension BrowserModel {
    /// Re-reads whether the page on screen is bookmarked. Called whenever the
    /// address changes.
    public func refreshBookmarkState() async {
        guard let url = selectedTab?.url else {
            chrome.isBookmarked = false
            return
        }
        chrome.isBookmarked = await bookmarks.bookmark(for: url, in: currentSpaceID) != nil
    }

    /// ⌘D: saves the page, or removes the bookmark it already has.
    public func toggleBookmark() async {
        guard let tab = selectedTab, let url = tab.url else { return }
        let spaceID = currentSpaceID
        if let existing = await bookmarks.bookmark(for: url, in: spaceID) {
            await bookmarks.delete(existing.id)
        } else {
            await bookmarks.save(
                Bookmark(url: url, title: tab.title, spaceID: spaceID, isFavorite: true)
            )
        }
        await refreshBookmarkState()
    }
}
