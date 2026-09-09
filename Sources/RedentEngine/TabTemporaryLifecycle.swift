import Foundation
import RedentKit

/// The temporary tab role: creation, expiry, and promotion back to a normal
/// tab. Split from `TabController.swift` so the core lifecycle stays readable.
extension TabController {
    @discardableResult
    public func newTemporaryTab(url: URL?, expiresAt: Date?) -> any BrowserTab {
        var snapshot = TabSnapshot(url: url)
        snapshot.spaceID = workspace.selectedSpaceID
        snapshot.containerID = workspace.spaces.first { $0.id == workspace.selectedSpaceID }?.containerID
        snapshot.lifespan = .temporary(sessionID: UUID(), expiresAt: expiresAt, cleanupOnClose: true)
        let tab = WebTab(snapshot: snapshot, controller: self)
        webTabs.insert(tab, at: insertIndexAfterCurrent())
        updateSelectedID(tab.id)
        tab.wake(loading: url)
        changed()
        logger.notice("newTemporaryTab")
        return tab
    }

    /// Keeping a tab moves it out of its ephemeral store into the Space's
    /// Container, so the live view is rebuilt rather than reused.
    public func keepTab(_ id: UUID) {
        guard let tab = webTabs.first(where: { $0.id == id }), tab.snapshot.isTemporary else { return }
        undoHistory.record(session)
        let url = tab.url ?? tab.snapshot.url
        tab.hibernate()
        tab.snapshot.lifespan = .normal
        if tab.snapshot.containerID == nil {
            tab.snapshot.containerID = workspace.spaces
                .first { $0.id == tab.snapshot.spaceID }?.containerID
        }
        tab.wake(loading: url)
        changed()
    }

    @discardableResult
    public func sweepExpiredTabs(now: Date) -> UUID? {
        // Runs on the window's clock every second. Copying every tab's snapshot
        // to discover there is nothing temporary is work for the common case.
        guard webTabs.contains(where: { $0.snapshot.lifespan.expiresAt != nil }) else { return nil }
        let decision = TabExpiryPolicy().decide(
            tabs: webTabs.map(\.snapshot), selectedID: selectedID, now: now
        )
        guard !decision.isEmpty else { return nil }
        for id in decision.closing { close(id) }
        return decision.prompting
    }
}
