import Foundation

@MainActor
public protocol BrowserControlling: AnyObject {
    var tabs: [any BrowserTab] { get }
    var selectedID: UUID? { get set }
    var selectedTab: (any BrowserTab)? { get }
    var session: BrowserSession { get }
    var visibleTabs: [any BrowserTab] { get }
    var canReopen: Bool { get }
    var canUndo: Bool { get }
    var canUndoSpaces: Bool { get }
    /// A private window: every tab browses in one ephemeral session, nothing is
    /// written to history, and the workspace is never saved.
    var isPrivate: Bool { get }
    func perform(_ action: WorkspaceAction) throws
    func undo()
    /// Rewinds the latest Space edit only, leaving later tab changes alone.
    func undoSpaces()
    var signalHandler: (any PageSignalHandling)? { get set }
    var onChange: (@MainActor () -> Void)? { get set }
    var onNavigation: (@MainActor (TabSnapshot, UUID) -> Void)? { get set }
    func apply(settings: BrowserSettings)
    /// Restores starter Spaces with one blank tab and drops transient undo state.
    func resetWorkspace()
    @discardableResult func newTab(url: URL?) -> any BrowserTab
    /// Opens a tab in the current Space without selecting it.
    @discardableResult func newBackgroundTab(url: URL) -> any BrowserTab
    /// Opens a tab in the temporary role: excluded from history, session
    /// restore, and the reopen stack, with its own ephemeral storage.
    @discardableResult func newTemporaryTab(url: URL?, expiresAt: Date?) -> any BrowserTab
    /// Promotes a temporary tab to a normal one. The storage boundary changes,
    /// so the page reloads.
    func keepTab(_ id: UUID)
    /// Closes expired background tabs.
    /// - Returns: the selected tab now asking to be kept or closed, if any.
    @discardableResult func sweepExpiredTabs(now: Date) -> UUID?
    /// Opens a copy of the tab right after it and selects the copy.
    @discardableResult func duplicateTab(_ id: UUID) -> (any BrowserTab)?
    func close(_ id: UUID)
    /// Closes several tabs as one reversible operation.
    func closeTabs(_ ids: Set<UUID>)
    func closeOthers(than id: UUID)
    func select(_ id: UUID)
    func selectPreviouslyActiveTab()
    func selectNext()
    func selectPrevious()
    func move(fromOffsets: IndexSet, toOffset: Int)
    /// Commits a live drag: `ids` is the visual order after the lifted tab
    /// landed. Tabs not named keep their relative seats.
    func applyOrder(_ ids: [UUID])
    func togglePin(_ id: UUID)
    func reopenLastClosed()
    /// Recently closed tabs and tab groups, newest first. Empty in private windows.
    var recentlyClosed: [RecentlyClosedEntry] { get }
    /// Restores one stack entry by id and removes only that record.
    func reopenClosed(_ entryID: UUID)
    /// Closes every tab in a user group as one reopenable group entry.
    func closeGroup(_ groupID: UUID)
    /// Drops every reopen and undo record that would bring a forgotten site
    /// back into the window.
    /// - Returns: how many closed-tab records were discarded.
    @discardableResult func forgetClosedTabs(matching domain: String) -> Int
    /// - Parameter keeping: every tab currently on screen. A split window shows
    ///   more than one, and none of them may be torn down underneath the user.
    func sweepHibernation(now: Date, keeping: Set<UUID>)
    /// Opens the connection to `url`'s origin ahead of a likely navigation.
    func preconnect(to url: URL)
    /// Loads the results page for a search ahead of return; `nil` drops it.
    func prerender(_ url: URL?)
    /// Shows or hides Chrome's DevTools under the tab's page.
    func toggleDevTools(_ id: UUID)
    /// Opens DevTools on the Console, or closes them if they are open.
    func toggleConsole(_ id: UUID)
    func isShowingDevTools(_ id: UUID) -> Bool
    /// Replaces shared Spaces, groups, and pins. Existing web views stay put.
    func importSyncedWorkspace(_ session: BrowserSession)
    /// Backdates idle tabs in a Space for Tidy Tabs demos in Settings → Testing.
    func backdateInactiveTabsForTidyDemo(spaceID: UUID?, lastActiveAt: Date)
}

extension BrowserControlling {
    /// A controller without an engine behind it — a test double — has no
    /// DevTools to show.
    public func toggleDevTools(_ id: UUID) {}
    public func toggleConsole(_ id: UUID) {}
    public func isShowingDevTools(_ id: UUID) -> Bool { false }
    public func importSyncedWorkspace(_ session: BrowserSession) {}
    public var recentlyClosed: [RecentlyClosedEntry] { [] }
    public func reopenClosed(_ entryID: UUID) {}
    public func closeGroup(_ groupID: UUID) {}
    public func backdateInactiveTabsForTidyDemo(spaceID: UUID?, lastActiveAt: Date) {}

    @discardableResult
    public func newBackgroundTab(url: URL) -> any BrowserTab {
        let current = selectedID
        defer { selectedID = current }
        return newTab(url: url)
    }
}
