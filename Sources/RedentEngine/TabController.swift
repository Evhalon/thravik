import Foundation
import Observation
import RedentKit

/// Owns every tab, selection, ordering, and the hibernation sweep. Restores
/// from the injected `BrowserSession` at init and exposes the current
/// session for the app to persist.
@MainActor
@Observable
public final class TabController: BrowserControlling {
    /// `internal(set)` rather than `private(set)`: the ordering rules live in
    /// their own file to stay under the line limit, and must be able to mutate it.
    public internal(set) var webTabs: [WebTab]
    public var selectedID: UUID?
    public var tabs: [any BrowserTab] { webTabs }
    @ObservationIgnored public var onChange: (@MainActor () -> Void)?
    @ObservationIgnored public var onNavigation: (@MainActor (TabSnapshot, UUID) -> Void)?

    /// Weak: the app's own view model owns this controller's lifetime, not
    /// the other way around.
    public weak var signalHandler: (any PageSignalHandling)?

    /// Set by the composition root. The engine only asks; the decision about a
    /// site's camera or microphone belongs to the user's stored policy.
    @ObservationIgnored
    public var permissionDecider: (@MainActor (SiteKey, SitePermission) -> PermissionDecision)?

    /// Where a file the page hands over goes. Shared with every other window,
    /// and set by the composition root; nil in tests, where a download is
    /// simply declined.
    @ObservationIgnored public weak var downloads: DownloadCoordinator?

    /// Shared with every other window: one registry per process (see
    /// `BrowsingContextRegistry`).
    @ObservationIgnored let contexts: BrowsingContextRegistry
    /// Non-nil in a private window. Every tab it opens browses in this one
    /// ephemeral session, so sibling tabs share a login and nothing outlives
    /// the window.
    @ObservationIgnored public let privateSessionID: UUID?
    @ObservationIgnored let warmer = WebViewWarmer()
    @ObservationIgnored let contentBlocker = ContentBlocker()
    @ObservationIgnored let faviconFetcher = FaviconFetcher()
    @ObservationIgnored private(set) var settings: BrowserSettings
    @ObservationIgnored let logger: any EventLogging
    @ObservationIgnored var closedStack: [TabSnapshot] = []
    @ObservationIgnored var previouslySelectedID: UUID?
    static let closedStackLimit = 10
    var workspace: BrowserSession
    let undoHistory = BrowserUndoHistory()
    public var isPrivate: Bool { privateSessionID != nil }
    public var canReopen: Bool { !closedStack.isEmpty }
    public var canUndo: Bool { undoHistory.canUndo }
    /// Filters `webTabs` rather than `tabs`: the latter boxes every tab into an
    /// existential first, and this is read on every sidebar render.
    public var visibleTabs: [any BrowserTab] {
        webTabs.filter { $0.snapshot.spaceID == workspace.selectedSpaceID }
    }

    public init(
        session: BrowserSession,
        settings: BrowserSettings,
        logger: any EventLogging,
        contexts: BrowsingContextRegistry = BrowsingContextRegistry(),
        privateSessionID: UUID? = nil
    ) {
        // Through the reducer, so a restored selection that names a tab in
        // another Space cannot leave the window showing nothing.
        let normalized = WorkspaceState(session: session).session
        self.contexts = contexts
        self.privateSessionID = privateSessionID
        self.workspace = normalized
        self.settings = settings
        self.logger = logger
        self.selectedID = normalized.selectedTabID
        self.webTabs = normalized.tabs.map { WebTab(snapshot: $0, controller: nil) }
        for tab in webTabs { tab.controller = self }
        contexts.sync(webTabs.map(\.snapshot.browsingContext), owner: ObjectIdentifier(self))
        contentBlocker.onCompiled = { [weak self] in self?.installCompiledBlockList() }
        contentBlocker.startCompilingIfNeeded()
        // Silence here would mean no ad blocking and no page bridge — so no
        // autofill and no OTP detection — with nothing to show for it.
        if EngineResources.bundle == nil { logger.error("engineResourceBundleMissing") }
    }

    /// Kept in sync by the app when settings change.
    public func apply(settings: BrowserSettings) {
        let blockingChanged = settings.blocksTrackers != self.settings.blocksTrackers
        self.settings = settings
        // Every settings write lands here, including the one a live sidebar drag
        // makes each frame. Swapping a rule list on a running web view forces the
        // content process to re-evaluate the page, so it happens only on a real
        // change to the toggle.
        guard blockingChanged else { return }
        for tab in webTabs {
            tab.applySettingsChange(blocksTrackers: settings.blocksTrackers)
        }
    }

    @discardableResult
    public func newTab(url: URL?) -> any BrowserTab {
        undoHistory.record(session)
        var snapshot = TabSnapshot(url: url)
        snapshot.spaceID = workspace.selectedSpaceID
        snapshot.containerID = workspace.spaces.first { $0.id == workspace.selectedSpaceID }?.containerID
        if let privateSessionID {
            snapshot.lifespan = .temporary(sessionID: privateSessionID, expiresAt: nil, cleanupOnClose: true)
        }
        let tab = WebTab(snapshot: snapshot, controller: self)
        webTabs.insert(tab, at: insertIndexAfterCurrent())
        updateSelectedID(tab.id)
        // A tab with no address shows Redent's own new-tab page, which is not a
        // web view. Building one anyway is what made ⌘T stutter.
        if let url { tab.wake(loading: url) } else { warmUp() }
        changed()
        logger.notice("newTab")
        return tab
    }

    public func close(_ id: UUID) {
        guard let index = webTabs.firstIndex(where: { $0.id == id }) else { return }
        let tab = webTabs[index]
        if !tab.snapshot.isTemporary { undoHistory.record(session) }
        if selectedID == id { updateSelectedID(selectionAfterClosing(id)) }
        tab.hibernate()
        webTabs.remove(at: index)
        pruneRelatedAfterRemoval()
        if !tab.snapshot.isTemporary { pushClosed(tab.snapshot) }
        changed()
    }

    /// The window closed. Releasing the hold here rather than in `deinit` keeps
    /// the ephemeral store's lifetime tied to the window the user closed, not to
    /// whenever the last view referencing this controller happens to go away.
    public func retire() {
        for tab in webTabs { tab.hibernate() }
        contexts.release(owner: ObjectIdentifier(self))
        warmer.discard()
    }

    func pushClosed(_ snapshot: TabSnapshot) {
        closedStack.append(snapshot)
        if closedStack.count > Self.closedStackLimit {
            closedStack.removeFirst()
        }
    }
}
