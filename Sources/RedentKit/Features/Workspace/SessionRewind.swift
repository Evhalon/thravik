import Foundation

/// Merges an undo record into the live session, touching only its own scope.
/// A whole-session restore would also throw away every tab change made since
/// the record was taken.
public enum SessionRewind {
    public static func rewind(_ current: BrowserSession, to previous: BrowserSession, scope: UndoScope) -> BrowserSession {
        switch scope {
        case .tabs: tabs(current, to: previous)
        case .spaces: spaces(current, to: previous)
        }
    }

    /// Restores the tab layout but keeps today's Spaces. Tabs of a Space deleted
    /// since stay gone: undoing that deletion is what brings them back.
    private static func tabs(_ current: BrowserSession, to previous: BrowserSession) -> BrowserSession {
        let live = Set(current.spaces.map(\.id))
        var next = previous
        next.spaces = current.spaces
        next.tabs.removeAll { !isIn(live, $0.spaceID) }
        next.tabs += current.tabs.filter { $0.isTemporary && isIn(live, $0.spaceID) }
        next.groups.removeAll { !live.contains($0.spaceID) }
        if !isIn(live, next.selectedSpaceID) { next.selectedSpaceID = current.selectedSpaceID }
        return normalized(next)
    }

    /// Restores the Spaces and the tabs of any Space it revives, leaving every
    /// other tab exactly where it is now.
    private static func spaces(_ current: BrowserSession, to previous: BrowserSession) -> BrowserSession {
        let restored = Set(previous.spaces.map(\.id))
        let revived = restored.subtracting(current.spaces.map(\.id))
        let liveTabIDs = Set(current.tabs.map(\.id))
        let fallback = previous.selectedSpaceID ?? previous.spaces.first?.id
        var next = current
        next.spaces = previous.spaces
        next.tabs += previous.tabs.filter { isIn(revived, $0.spaceID) && !liveTabIDs.contains($0.id) }
        next.groups += previous.groups.filter { revived.contains($0.spaceID) }
        // A Space that no longer exists after the undo cannot take its tabs
        // with it — they were opened after the record and are the user's work.
        next.tabs = next.tabs.map { tab in
            guard !isIn(restored, tab.spaceID) else { return tab }
            var moved = tab
            moved.spaceID = fallback
            moved.groupID = nil
            return moved
        }
        next.groups.removeAll { !restored.contains($0.spaceID) }
        if !isIn(restored, next.selectedSpaceID) { next.selectedSpaceID = fallback }
        return normalized(next)
    }

    private static func isIn(_ ids: Set<UUID>, _ id: UUID?) -> Bool {
        id.map(ids.contains) ?? false
    }

    private static func normalized(_ session: BrowserSession) -> BrowserSession {
        var state = WorkspaceState(session: session)
        state.normalizeContainers()
        return state.session
    }
}
