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
    public internal(set) var pageTrustIssue: PageTrustIssue?
    public internal(set) var progress: Double = 0
    public internal(set) var isLoading: Bool = false
    public internal(set) var canGoBack: Bool = false
    public internal(set) var canGoForward: Bool = false
    public internal(set) var isHibernated: Bool = true
    public internal(set) var themeColor: Color?
    public internal(set) var zoom: Double
    public internal(set) var isPlayingAudio = false
    public internal(set) var isMuted = false
    public internal(set) var volume: Double = 1
    public internal(set) var isReaderActive = false
    public internal(set) var canFloatVideo = false
    public internal(set) var isVideoFloating = false
    public internal(set) var isVideoPlaying = false
    public internal(set) var didAutoFloatVideo = false
    public internal(set) var mediaSessionTitle: String?
    public internal(set) var mediaSessionArtist: String?
    public internal(set) var mediaSessionArtworkURL: URL?
    public internal(set) var lastMediaActivityAt: Date?
    public internal(set) var videoPlayback = FloatingVideoPlayback()
    public internal(set) var quietReceipt = QuietReceipt()

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
    @ObservationIgnored var attemptedURL: URL?
    @ObservationIgnored var acceptedInvalidCertificateKeys: Set<SiteKey> = []
    /// Bounded by the timeline's own cap, and released with the web view: these
    /// keep a whole back/forward list alive otherwise.
    @ObservationIgnored var liveItems: [UUID: WKBackForwardListItem] = [:]
    /// Observed: a prerendered search can replace the view of a tab that is
    /// already awake, and the host has to show the new one.
    var webView: WKWebView?
    @ObservationIgnored var displacedPages = DisplacedPages()
    @ObservationIgnored var navigationDelegate: WebTabNavigationDelegate?
    @ObservationIgnored var signalRouter: PageSignalRouter?
    @ObservationIgnored var observationTokens: [NSKeyValueObservation] = []
    @ObservationIgnored var audibleFrames: Set<String> = []
    @ObservationIgnored var floatingVideoPanel: FloatingVideoPanel?
    @ObservationIgnored var videoAspectRatio = 16.0 / 9.0
    @ObservationIgnored var floatingVideoRequestID: UInt = 0
    @ObservationIgnored var floatingVideoOpening = false
    @ObservationIgnored let pageFinder = WebPageFinder()
    /// Chrome's DevTools docked under the page, while open. It keeps the tab
    /// awake, and closes with the web view it inspects.
    var devToolsPanel: DevToolsPanel?

    init(snapshot: TabSnapshot, controller: TabController?) {
        var snapshot = snapshot
        // A failed first load used to erase the address and it was saved that
        // way; the tab's own path still knows where it was.
        snapshot.url = snapshot.url ?? snapshot.timeline.current?.url
        self.id = snapshot.id
        self.snapshot = snapshot
        self.title = snapshot.title
        self.url = snapshot.url
        self.pageTrustIssue = nil
        self.attemptedURL = snapshot.url
        self.origin = snapshot.url.flatMap(Origin.init(url:))
        self.isPinned = snapshot.isPinned
        self.zoom = snapshot.zoom
        self.controller = controller
    }

    public func load(_ url: URL) {
        if controller?.managedURLBlocker?(url) == true {
            blockOrganizationPolicy(for: url)
            return
        }
        beginNavigation(to: url)
        if adoptPrerendered(url) { return }
        if let webView { navigate(url, in: webView) } else { wake(loading: url) }
    }

    /// Applied to the live view and stored on the snapshot, so a hibernated tab
    /// comes back at the size the user left it.
    public func setZoom(_ level: Double) {
        let clamped = PageZoom.clamped(level)
        guard clamped != zoom else { return }
        zoom = clamped
        snapshot.zoom = clamped
        applyPageZoom()
    }

    public func goBack() {
        beginNavigation()
        if goBackToDisplacedPage() { return }
        webView?.goBack()
    }

    public func goForward() {
        beginNavigation()
        if goForwardToDisplacedPage() { return }
        webView?.goForward()
    }
    public func reload() {
        guard let webView else { return }
        let target = webView.url ?? url
        beginNavigation(to: target)
        BrowserUserAgent.apply(to: webView, for: target)
        webView.reload()
    }
    public func stopLoading() { webView?.stopLoading() }

    func handleProvisionalFailure(_ error: any Error) {
        guard let trustIssue = PageTrustIssueResolver.resolve(error) else { return }
        pageTrustIssue = trustIssue
        beginNavigation(to: attemptedURL)
        pageTrustIssue = trustIssue
    }

    func finishNavigation() {
        attemptedURL = nil
        controller?.contexts.pageDidLoad(in: snapshot.browsingContext)
        controller?.extensions?.tabDidLoad(self)
    }
}
