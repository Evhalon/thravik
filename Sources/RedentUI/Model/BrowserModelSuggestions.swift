import Foundation
import RedentKit

/// The address bar and new-tab field: typing, return, and opening a row.
extension BrowserModel {
    public func queryChanged(_ text: String, from source: AddressSuggestionsModel.Source) {
        let context = SuggestionContext(
            searchEngine: settings.searchEngine, spaceID: currentSpaceID, openTabs: switchableTabs
        )
        suggestions.update(query: text, from: source, context: context)
        // Whatever return would open right now — the search engine for a
        // query, the site for an address — gets its handshake started early.
        if let likely = AddressResolver.resolve(text, using: settings.searchEngine) {
            tabs.preconnect(to: likely)
        }
    }

    /// Return in the address bar. ⌘-return keeps the current page and opens
    /// the destination beside it.
    public func submitAddress(inNewTab: Bool = false) {
        if let row = suggestions.submission(for: address.text) {
            return open(row, inNewTab: inNewTab)
        }
        suggestions.close()
        guard let url = address.commit(using: settings.searchEngine) else { return }
        open(url, inNewTab: inNewTab)
    }

    /// Return in the new tab's field, which navigates the new tab itself.
    /// - Returns: whether anything was opened, so the field knows to clear.
    public func submitNewTabQuery(_ text: String) -> Bool {
        if let row = suggestions.submission(for: text) {
            open(row, inNewTab: false)
            return true
        }
        suggestions.close()
        guard let url = AddressResolver.resolve(text, using: settings.searchEngine) else { return false }
        navigate(to: url)
        return true
    }

    public func open(_ url: URL, inNewTab: Bool) {
        suggestions.close()
        address.finishEditing()
        if inNewTab { tabs.newTab(url: url) } else { navigate(to: url) }
    }

    public func open(_ row: AddressSuggestion, inNewTab: Bool) {
        guard let tabID = row.tabID else { return open(row.url, inNewTab: inNewTab) }
        suggestions.close()
        address.finishEditing()
        switchToTab(tabID)
    }

    /// Arrow keys in a TextField never reach `onMoveCommand`. The command bar
    /// already uses `onKeyPress`; the address fields must do the same.
    public func moveSuggestionHighlight(by offset: Int, from source: AddressSuggestionsModel.Source) -> Bool {
        guard suggestions.isOpen(for: source) else { return false }
        suggestions.moveHighlight(by: offset)
        return true
    }

    /// Switching away from a blank new tab closes it: it was only ever the
    /// place the user typed, and leaving it behind is clutter.
    private func switchToTab(_ id: UUID) {
        let blankTabID = selectedTab.flatMap { $0.url == nil ? $0.id : nil }
        do {
            try tabs.perform(.selectTab(id: id))
        } catch {
            actionError = "That tab has closed. Nothing was changed."
            return
        }
        if let blankTabID, blankTabID != id { tabs.close(blankTabID) }
        address.sync(with: selectedTab)
    }

    private var switchableTabs: [OpenTabCandidate] {
        tabs.tabs.compactMap { tab in
            guard tab.id != tabs.selectedID, !tab.snapshot.isTemporary, let url = tab.url else { return nil }
            return OpenTabCandidate(id: tab.id, title: tab.snapshot.displayTitle, url: url,
                                    faviconData: tab.snapshot.faviconData)
        }
    }
}
