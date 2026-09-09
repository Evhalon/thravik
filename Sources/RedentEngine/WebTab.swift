import WebKit
import SwiftUI
import Observation
import RedentKit

/// One browser tab: an observable mirror of a `WKWebView`'s state, plus the
/// `TabSnapshot` that survives hibernation and app restart.
///
/// `webView` is `nil` while hibernated. Every WebKit-facing helper method
/// lives in an extension in a sibling file — this file only holds the
/// observable surface and the simplest navigation calls.
@MainActor
@Observable
public final class WebTab: Identifiable, BrowserTab {
    public let id: UUID
    public internal(set) var snapshot: TabSnapshot
    public internal(set) var title: String
    public internal(set) var url: URL?
    public internal(set) var progress: Double = 0
    public internal(set) var isLoading: Bool = false
    public internal(set) var canGoBack: Bool = false
    public internal(set) var canGoForward: Bool = false
    public internal(set) var isHibernated: Bool = true
    public internal(set) var themeColor: Color?
    public internal(set) var zoom: Double

    public var isPinned: Bool {
        didSet { snapshot.isPinned = isPinned }
    }

    /// Stored, not computed: every tab row reads this on every render, and
    /// re-parsing the URL each time is a cost that scales with the tab count.
    public internal(set) var origin: Origin?

    /// Weak: `TabController` owns this tab strongly. A strong back-reference
    /// here would form a retain cycle that outlives the tab's own lifetime.
    @ObservationIgnored weak var controller: TabController?

    @ObservationIgnored let navigationEvents = TabNavigationEvents()
    @ObservationIgnored let timelineRecorder = TabTimelineRecorder()
    /// Bounded by the timeline's own cap, and released with the web view: these
    /// keep a whole back/forward list alive otherwise.
    @ObservationIgnored var liveItems: [UUID: WKBackForwardListItem] = [:]
    @ObservationIgnored var webView: WKWebView?
    @ObservationIgnored var navigationDelegate: WebTabNavigationDelegate?
    @ObservationIgnored var signalRouter: PageSignalRouter?
    @ObservationIgnored var observationTokens: [NSKeyValueObservation] = []

    init(snapshot: TabSnapshot, controller: TabController?) {
        self.id = snapshot.id
        self.snapshot = snapshot
        self.title = snapshot.title
        self.url = snapshot.url
        self.origin = snapshot.url.flatMap(Origin.init(url:))
        self.isPinned = snapshot.isPinned
        self.zoom = snapshot.zoom
        self.controller = controller
    }

    public func load(_ url: URL) {
        if webView == nil {
            wake(loading: url)
        } else if let webView {
            navigate(url, in: webView)
        }
    }

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

    /// Applied to the live view and stored on the snapshot, so a hibernated tab
    /// comes back at the size the user left it.
    public func setZoom(_ level: Double) {
        let clamped = PageZoom.clamped(level)
        guard clamped != zoom else { return }
        zoom = clamped
        snapshot.zoom = clamped
        webView?.pageZoom = clamped
    }

    public func goBack() { webView?.goBack() }
    public func goForward() { webView?.goForward() }
    public func reload() {
        guard let webView else { return }
        BrowserUserAgent.apply(to: webView, for: webView.url ?? url)
        webView.reload()
    }
    public func stopLoading() { webView?.stopLoading() }
}
