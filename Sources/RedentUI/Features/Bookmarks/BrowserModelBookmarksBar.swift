import AppKit
import RedentKit

extension BrowserModel {
    public var showsBookmarksBar: Bool { settings.showsBookmarksBar && !isFocusMode }

    public func toggleBookmarksBar() async {
        guard let spaceID = currentSpaceID else { return }
        async let pages = bookmarks.all(in: spaceID)
        async let folders = bookmarks.folders(in: spaceID)
        let items = await BookmarksBarCatalog.items(bookmarks: pages, folders: folders, spaceID: spaceID)
        guard currentSpaceID == spaceID, !Task.isCancelled, !items.isEmpty else { return }
        settings.showsBookmarksBar.toggle()
    }

    /// Plain click navigates; ⌘ opens behind the page; ⌘⇧ opens and goes there.
    public func openBookmarksBarURL(_ url: URL) {
        let flags = NSEvent.modifierFlags
        openBookmark(url, target: LinkActivation.target(
            isUserLink: true,
            commandHeld: flags.contains(.command),
            shiftHeld: flags.contains(.shift)
        ))
    }

    public func openBookmark(_ url: URL, target: LinkActivation.Target) {
        switch target {
        case .currentTab: open(url, inNewTab: false)
        case .foregroundTab: open(url, inNewTab: true)
        case .backgroundTab: tabs.newBackgroundTab(url: url)
        }
    }
}
