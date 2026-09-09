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
    /// A private window: every tab browses in one ephemeral session, nothing is
    /// written to history, and the workspace is never saved.
    var isPrivate: Bool { get }
    func perform(_ action: WorkspaceAction) throws
    func undo()
    var signalHandler: (any PageSignalHandling)? { get set }
    var onChange: (@MainActor () -> Void)? { get set }
    var onNavigation: (@MainActor (TabSnapshot, UUID) -> Void)? { get set }
    func apply(settings: BrowserSettings)
    /// Restores starter Spaces with one blank tab and drops transient undo state.
    func resetWorkspace()
    @discardableResult func newTab(url: URL?) -> any BrowserTab
    /// Opens a tab in the temporary role: excluded from history, session
    /// restore, and the reopen stack, with its own ephemeral storage.
    @discardableResult func newTemporaryTab(url: URL?, expiresAt: Date?) -> any BrowserTab
    /// Promotes a temporary tab to a normal one. The storage boundary changes,
    /// so the page reloads.
    func keepTab(_ id: UUID)
    /// Closes expired background tabs.
    /// - Returns: the selected tab now asking to be kept or closed, if any.
    @discardableResult func sweepExpiredTabs(now: Date) -> UUID?
    func close(_ id: UUID)
    func closeOthers(than id: UUID)
    func select(_ id: UUID)
    func selectNext()
    func selectPrevious()
    func move(fromOffsets: IndexSet, toOffset: Int)
    /// Commits a live drag: `ids` is the visual order after the lifted tab
    /// landed. Tabs not named keep their relative seats.
    func applyOrder(_ ids: [UUID])
    func togglePin(_ id: UUID)
    func reopenLastClosed()
    /// Drops every reopen and undo record that would bring a forgotten site
    /// back into the window.
    /// - Returns: how many closed-tab records were discarded.
    @discardableResult func forgetClosedTabs(matching domain: String) -> Int
    /// - Parameter keeping: every tab currently on screen. A split window shows
    ///   more than one, and none of them may be torn down underneath the user.
    func sweepHibernation(now: Date, keeping: Set<UUID>)
}
