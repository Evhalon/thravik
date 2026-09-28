import RedentKit
import WebKit

/// Moving along the path a tab has taken, which outlives its web view.
extension WebTab {
    public var timeline: [NavigationEntry] { snapshot.timeline.entries }

    /// Returns to an earlier point in this tab's path, using the live list when
    /// the item is still valid and reloading the URL when it is not.
    public func travel(to entry: NavigationEntry) {
        guard let webView, let item = liveItems[entry.id], isReachable(item, in: webView) else {
            load(entry.url)
            return
        }
        webView.go(to: item)
    }

    /// WebKit prunes forward items on a new navigation, so a stored item can
    /// outlive its place in the list.
    private func isReachable(_ item: WKBackForwardListItem, in webView: WKWebView) -> Bool {
        let list = webView.backForwardList
        return list.backList.contains(item) || list.forwardList.contains(item) || list.currentItem == item
    }

    public func forgetTimeline(domain: String) {
        snapshot.timeline.forget(domain: domain)
    }
}
