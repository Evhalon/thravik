import Foundation
import RedentKit
import WebKit

extension TabController {
    /// Adopts a window the page opened as a tab that keeps its opener.
    ///
    /// Handing WebKit back `nil` and loading the address in a fresh tab severs
    /// `window.opener`, and a sign-in popup — Google's above all — posts its
    /// result back through exactly that handle: the user signs in, the popup
    /// sits there, and the page that asked never hears an answer. The tab takes
    /// the view WebKit prepared instead, which keeps the pair connected.
    @discardableResult
    func openPopupTab(configuration: WKWebViewConfiguration, url: URL?, of parent: TabSnapshot) -> WebTab {
        let view = WebViewFactory.makePopupView(
            configuration: configuration,
            blocksTrackers: settings.blocksTrackers,
            contentBlocker: contentBlocker
        )
        BrowserUserAgent.apply(to: view, for: url)
        let tab = insertChildTab(url: url, of: parent)
        tab.adopt(view)
        publishChild(tab, of: parent)
        return tab
    }

    /// A popup belongs to the page that opened it: same Space, same Container,
    /// same temporary role. Routing it through the Space default would silently
    /// move a login flow into a different storage boundary.
    private func insertChildTab(url: URL?, of parent: TabSnapshot) -> WebTab {
        undoHistory.record(session)
        var snapshot = TabSnapshot(url: url)
        snapshot.spaceID = parent.spaceID ?? workspace.selectedSpaceID
        snapshot.containerID = parent.containerID
        snapshot.lifespan = parent.lifespan
        snapshot.parentTabID = parent.id
        snapshot.groupID = parent.groupID
        let tab = WebTab(snapshot: snapshot, controller: self)
        webTabs.insert(tab, at: insertIndexAfterCurrent())
        selectedID = tab.id
        return tab
    }

    /// Grouping the pair already republishes the session; announce the new tab
    /// only when it did not.
    private func publishChild(_ tab: WebTab, of parent: TabSnapshot) {
        if !adoptRelatedTab(parent: parent, child: tab) { changed() }
    }
}
