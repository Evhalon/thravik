import Foundation

public struct WorkspaceState: Codable, Sendable, Equatable {
    /// `internal(set)` rather than `private(set)`: the group rules live in
    /// their own file to stay under the line limit, and must be able to mutate it.
    public internal(set) var session: BrowserSession

    public init(session: BrowserSession = BrowserSession()) {
        self.session = session
        rebuildMembership()
        normalizeSelection()
    }

    public var selectedSpace: BrowserSpace? {
        session.spaces.first { $0.id == session.selectedSpaceID }
    }

    public mutating func apply(_ action: WorkspaceAction) throws {
        switch action {
        case let .createSpace(name): createSpace(name: name)
        case let .renameSpace(id, name): try renameSpace(id: id, name: name)
        case let .deleteSpace(id): try deleteSpace(id: id)
        case let .selectSpace(id): try selectSpace(id: id)
        case let .selectTab(id): try selectTab(id: id)
        case let .moveTab(id, toSpaceID, index): try moveTab(id: id, to: toSpaceID, index: index)
        case let .setPinned(id, isPinned): try setPinned(id: id, isPinned: isPinned)
        case .createGroup, .createGroupWithTabs, .renameGroup,
             .deleteGroup, .moveTabToGroup, .groupTabs:
            try applyGroup(action)
        }
        rebuildMembership()
        normalizeContainers()
        normalizeSelection()
    }

    private mutating func createSpace(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        session.spaces.append(BrowserSpace(name: trimmed))
    }

    private mutating func renameSpace(id: UUID, name: String) throws {
        guard let index = session.spaces.firstIndex(where: { $0.id == id }) else { throw WorkspaceActionError.missingSpace(id) }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        session.spaces[index].name = trimmed
    }

    private mutating func deleteSpace(id: UUID) throws {
        guard session.spaces.contains(where: { $0.id == id }) else { throw WorkspaceActionError.missingSpace(id) }
        guard session.spaces.count > 1 else { throw WorkspaceActionError.cannotDeleteLastSpace }
        let removedTabIDs = Set(session.tabs.filter { $0.spaceID == id }.map(\.id))
        session.tabs.removeAll { $0.spaceID == id }
        session.groups.removeAll { $0.spaceID == id }
        session.spaces.removeAll { $0.id == id }
        if session.selectedSpaceID == id { session.selectedSpaceID = session.spaces.first?.id }
        if let selectedTabID = session.selectedTabID, removedTabIDs.contains(selectedTabID) {
            session.selectedTabID = session.spaces.first?.selectedTabID ?? session.tabs.first?.id
        }
    }

    private mutating func selectSpace(id: UUID) throws {
        guard let space = session.spaces.first(where: { $0.id == id }) else { throw WorkspaceActionError.missingSpace(id) }
        session.selectedSpaceID = id
        session.selectedTabID = space.selectedTabID ?? session.tabs.first { $0.spaceID == id }?.id
    }

    private mutating func selectTab(id: UUID) throws {
        guard let tab = session.tabs.first(where: { $0.id == id }) else { throw WorkspaceActionError.missingTab(id) }
        session.selectedTabID = id
        if let spaceID = tab.spaceID { session.selectedSpaceID = spaceID }
    }

    private mutating func moveTab(id: UUID, to spaceID: UUID, index: Int?) throws {
        guard session.tabs.contains(where: { $0.id == id }) else { throw WorkspaceActionError.missingTab(id) }
        guard session.spaces.contains(where: { $0.id == spaceID }) else { throw WorkspaceActionError.missingSpace(spaceID) }
        guard let tabIndex = session.tabs.firstIndex(where: { $0.id == id }) else { return }
        var tab = session.tabs.remove(at: tabIndex)
        tab.spaceID = spaceID
        tab.groupID = nil
        tab.parentTabID = nil
        detachChildren(of: id)
        let destination = session.tabs.enumerated().filter { $0.element.spaceID == spaceID }.map(\.offset)
        let insertion = min(max(index ?? destination.count, 0), destination.count)
        let absolute = destination.indices.contains(insertion) ? destination[insertion] : (destination.last.map { $0 + 1 } ?? session.tabs.count)
        session.tabs.insert(tab, at: absolute)
        session.selectedSpaceID = spaceID
        session.selectedTabID = id
    }

    private mutating func setPinned(id: UUID, isPinned: Bool) throws {
        guard let index = session.tabs.firstIndex(where: { $0.id == id }) else { throw WorkspaceActionError.missingTab(id) }
        session.tabs[index].isPinned = isPinned
        guard isPinned else { return }
        session.tabs[index].groupID = nil
        session.tabs[index].parentTabID = nil
        detachChildren(of: id)
        let tab = session.tabs.remove(at: index)
        let insertion = session.tabs.firstIndex { $0.spaceID == tab.spaceID && !$0.isPinned }
            ?? session.tabs.lastIndex { $0.spaceID == tab.spaceID }.map { $0 + 1 }
            ?? session.tabs.count
        session.tabs.insert(tab, at: insertion)
    }

    private mutating func rebuildMembership() {
        for index in session.spaces.indices {
            let id = session.spaces[index].id
            session.spaces[index].tabIDs = session.tabs.filter { $0.spaceID == id }.map(\.id)
            session.spaces[index].groupIDs = session.groups.filter { $0.spaceID == id }.map(\.id)
            let selected = session.spaces[index].selectedTabID
            let globalSelection = session.selectedTabID.flatMap { id in
                session.tabs.first { $0.id == id && $0.spaceID == session.spaces[index].id }?.id
            }
            session.spaces[index].selectedTabID = selected.flatMap { id in
                session.spaces[index].tabIDs.contains(id) ? id : nil
            } ?? globalSelection ?? session.spaces[index].tabIDs.first
        }
        for index in session.groups.indices {
            let id = session.groups[index].id
            session.groups[index].tabIDs = session.tabs.filter { $0.groupID == id }.map(\.id)
        }
        session.groups.removeAll { group in !session.tabs.contains { $0.groupID == group.id } }
    }

    private mutating func detachChildren(of id: UUID) {
        for index in session.tabs.indices where session.tabs[index].parentTabID == id {
            session.tabs[index].parentTabID = nil
        }
    }

    /// A tab selected outside the active Space is invisible: only that Space's
    /// tabs are rendered. Anchor the selection to the Space, not the reverse.
    private mutating func normalizeSelection() {
        let known = Set(session.spaces.map(\.id))
        if session.selectedSpaceID.map({ !known.contains($0) }) ?? true {
            session.selectedSpaceID = session.spaces.first?.id
        }
        guard let spaceID = session.selectedSpaceID else {
            session.selectedTabID = nil
            return
        }
        let visible = session.tabs.contains { $0.id == session.selectedTabID && $0.spaceID == spaceID }
        guard !visible else { return }
        session.selectedTabID = session.spaces.first { $0.id == spaceID }?.selectedTabID
            ?? session.tabs.first { $0.spaceID == spaceID }?.id
    }
}
