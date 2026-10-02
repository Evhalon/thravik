import Foundation
import RedentKit

extension BrowserModel {
    public var canFindNext: Bool { hasPage && !chrome.findQuery.isEmpty }

    public func showFindBar() {
        guard hasPage else { return }
        findPageContextChanged()
        let wasHidden = !chrome.isFindBarVisible
        if wasHidden { chrome.isCapturingFindSelection = true }
        chrome.showFindBar()
        guard wasHidden else { return }
        searchPage(FindSession.Request(query: chrome.findQuery, seedsSelection: true))
    }

    public func closeFindBar() {
        guard chrome.isFindBarVisible else { return }
        chrome.hideFindBar()
        selectedTab?.clearFindHighlight()
        selectedTab?.focusPage()
    }

    public func findNext(forward: Bool = true) {
        guard hasPage else { return }
        findPageContextChanged()
        if chrome.isCapturingFindSelection {
            chrome.isCapturingFindSelection = false
            chrome.findSession.invalidate()
        }
        if !chrome.isFindBarVisible { chrome.showFindBar() }
        searchPage(FindSession.Request(query: chrome.findQuery, forward: forward))
    }

    public func findQueryChanged() {
        guard chrome.isFindBarVisible else { return }
        chrome.isCapturingFindSelection = false
        searchPage(FindSession.Request(query: chrome.findQuery, delay: .milliseconds(150)))
    }

    func findPageContextChanged() {
        let session = chrome.findSession
        let context = FindSession.Context(tab: selectedTab)
        guard context != session.context else { return }
        let previousID = session.context?.tabID
        session.context = context
        session.invalidate()
        chrome.isCapturingFindSelection = false
        chrome.findMatches = nil
        if let previousID { tabs.tabs.first { $0.id == previousID }?.clearFindHighlight() }
        guard context.url != nil else {
            chrome.hideFindBar()
            return
        }
        guard chrome.isFindBarVisible, !context.isLoading, !chrome.findQuery.isEmpty else { return }
        searchPage(FindSession.Request(query: chrome.findQuery))
    }

    private func searchPage(_ request: FindSession.Request) {
        guard let tab = selectedTab else { return }
        let context = FindSession.Context(tab: tab)
        chrome.findSession.search(request, on: tab, chrome: chrome) { [weak self] in
            guard let self else { return false }
            return self.chrome.isFindBarVisible && FindSession.Context(tab: self.selectedTab) == context
        }
    }
}
