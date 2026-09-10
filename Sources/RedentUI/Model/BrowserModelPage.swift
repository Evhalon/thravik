import AppKit
import Foundation
import RedentKit

/// The page commands every browser is expected to have: reload, stop, home,
/// find, print, and the address itself.
extension BrowserModel {
    public func reloadPage() { selectedTab?.reload() }

    /// ⇧⌘R: past the cache, for a page that is serving a stale copy of itself.
    public func reloadIgnoringCache() { selectedTab?.reloadIgnoringCache() }

    public func stopLoading() { selectedTab?.stopLoading() }

    public var isPageLoading: Bool { selectedTab?.isLoading ?? false }

    public func goBack() { selectedTab?.goBack() }
    public func goForward() { selectedTab?.goForward() }
    public var canGoBack: Bool { selectedTab?.canGoBack ?? false }
    public var canGoForward: Bool { selectedTab?.canGoForward ?? false }

    /// The homepage the user chose in Settings. An unparseable one is left
    /// alone rather than sent to a search engine behind their back.
    public func goHome() {
        guard let url = URL(string: settings.homepage), url.scheme != nil else { return }
        navigate(to: url)
    }

    public func printPage() { selectedTab?.printPage() }

    public var hasPage: Bool { selectedTab?.url != nil }

    public func copyAddress() {
        guard let url = selectedTab?.url else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(url.absoluteString, forType: .string)
    }

    /// ⌘L. A new tab has no address bar of its own, so the caret goes to the
    /// search field in the middle of the page instead. Focus mode ends either
    /// way: there is no address bar on screen to type into while it is on.
    public func focusAddressBar() {
        isFocusMode = false
        if hasPage {
            chrome.focusAddress()
        } else {
            requestCenterSearchFocus()
        }
    }

    public func showFindBar() {
        guard hasPage else { return }
        chrome.showFindBar()
    }

    public func closeFindBar() {
        chrome.hideFindBar()
        selectedTab?.clearFindHighlight()
    }

    /// - Parameter forward: ⌘G searches on, ⇧⌘G searches back.
    public func findNext(forward: Bool = true) {
        let query = chrome.findQuery
        guard let tab = selectedTab, !query.isEmpty else { return }
        Task { chrome.findFailed = !(await tab.findInPage(query, forward: forward)) }
    }

    /// ⌘1…⌘8 pick a tab in the current Space; ⌘9 is always the last one.
    public func selectTab(at index: Int) {
        let visible = tabs.visibleTabs
        guard !visible.isEmpty else { return }
        let target = index >= 9 ? visible.count - 1 : index - 1
        guard visible.indices.contains(target) else { return }
        tabs.select(visible[target].id)
    }
}
