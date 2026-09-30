import Foundation
import RedentKit

extension BrowserModel {
    public func dismissFloatingNewTab() {
        showsFloatingNewTab = false
        suggestions.close(from: .newTab)
    }

    /// Escape keeps the page below, so nothing the panel loaded ahead is wanted.
    func cancelFloatingNewTab() {
        dismissFloatingNewTab()
        prerenderSchedule.queryChanged("", search: nil, on: tabs)
    }

    /// The row the arrows land on is where return goes: load it now, as the
    /// address bar does. Open tabs are already loaded and a blank tab has nothing.
    func loadAhead(_ item: FloatingNewTabItem) {
        switch item.target {
        case .page(let url): prerenderSchedule.prerenderNow(url, on: tabs)
        case .suggestion(let row) where loadsAhead(row): prerenderSchedule.prerenderNow(row.url, on: tabs)
        case .tab, .blank, .suggestion: break
        }
    }

    public func submitFloatingNewTabQuery(_ text: String) {
        if let row = suggestions.submission(for: text) {
            openFloatingNewTabSuggestion(row)
            return
        }
        let url = AddressResolver.resolve(text, using: settings.searchEngine)
        dismissFloatingNewTab()
        tabs.newTab(url: url)
        if url == nil { requestCenterSearchFocus() }
    }

    public func openFloatingNewTabSuggestion(_ row: AddressSuggestion) {
        dismissFloatingNewTab()
        open(row, inNewTab: true)
    }

    func activateFloatingNewTab(_ item: FloatingNewTabItem) {
        switch item.target {
        case .tab(let id):
            dismissFloatingNewTab()
            tabs.select(id)
        case .page(let url):
            dismissFloatingNewTab()
            tabs.newTab(url: url)
        case .blank:
            dismissFloatingNewTab()
            tabs.newTab(url: nil)
            requestCenterSearchFocus()
        case .suggestion(let row):
            openFloatingNewTabSuggestion(row)
        }
    }
}
