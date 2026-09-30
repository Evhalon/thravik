import Foundation
import RedentKit

extension BrowserModel {
    public func dismissFloatingNewTab() {
        showsFloatingNewTab = false
        suggestions.close(from: .newTab)
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
