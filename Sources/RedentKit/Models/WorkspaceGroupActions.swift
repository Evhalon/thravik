import Foundation

/// Group mutations, split out of `WorkspaceState.swift` so the reducer's core
/// selection and Space rules stay readable on their own.
extension WorkspaceState {
    /// The outer reducer's switch stays exhaustive, so a new case is a compile
    /// error there rather than a silent no-op here.
    mutating func applyGroup(_ action: WorkspaceAction) throws {
        switch action {
        case let .createGroup(spaceID, name): try createGroup(spaceID: spaceID, name: name)
        case let .createGroupWithTabs(spaceID, name, tabIDs):
            try createGroupWithTabs(spaceID: spaceID, name: name, tabIDs: tabIDs)
        case let .renameGroup(id, name): try renameGroup(id: id, name: name)
        case let .deleteGroup(id): try deleteGroup(id: id)
        case let .moveTabToGroup(tabID, groupID): try moveTabToGroup(tabID: tabID, groupID: groupID)
        case let .groupTabs(groupID, tabIDs): try groupTabs(groupID: groupID, tabIDs: tabIDs)
        default: return
        }
    }

    private mutating func createGroup(spaceID: UUID, name: String) throws {
        guard session.spaces.contains(where: { $0.id == spaceID }) else { throw WorkspaceActionError.missingSpace(spaceID) }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var group = BrowserGroup(spaceID: spaceID, name: trimmed)
        group.colorToken = SpaceIdentity.derived(from: group.id).colorToken
        session.groups.append(group)
    }

    private mutating func createGroupWithTabs(spaceID: UUID, name: String, tabIDs: [UUID]) throws {
        try createGroup(spaceID: spaceID, name: name)
        guard let groupID = session.groups.last?.id else { return }
        try groupTabs(groupID: groupID, tabIDs: tabIDs)
    }

    private mutating func renameGroup(id: UUID, name: String) throws {
        guard let index = session.groups.firstIndex(where: { $0.id == id }) else { throw WorkspaceActionError.missingGroup(id) }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        session.groups[index].name = trimmed
    }

    private mutating func moveTabToGroup(tabID: UUID, groupID: UUID?) throws {
        guard let tabIndex = session.tabs.firstIndex(where: { $0.id == tabID }) else { throw WorkspaceActionError.missingTab(tabID) }
        guard let groupID else {
            session.tabs[tabIndex].groupID = nil
            session.tabs[tabIndex].parentTabID = nil
            return
        }
        guard let group = session.groups.first(where: { $0.id == groupID }) else { throw WorkspaceActionError.missingGroup(groupID) }
        guard session.tabs[tabIndex].spaceID == group.spaceID else { throw WorkspaceActionError.groupSpaceMismatch }
        session.tabs[tabIndex].groupID = groupID
    }

    private mutating func deleteGroup(id: UUID) throws {
        guard session.groups.contains(where: { $0.id == id }) else { throw WorkspaceActionError.missingGroup(id) }
        session.groups.removeAll { $0.id == id }
        for index in session.tabs.indices where session.tabs[index].groupID == id {
            session.tabs[index].groupID = nil
        }
    }

    private mutating func groupTabs(groupID: UUID, tabIDs: [UUID]) throws {
        guard let group = session.groups.first(where: { $0.id == groupID }) else { throw WorkspaceActionError.missingGroup(groupID) }
        let candidates = Set(tabIDs)
        for id in candidates {
            guard let tab = session.tabs.first(where: { $0.id == id }) else { throw WorkspaceActionError.missingTab(id) }
            guard tab.spaceID == group.spaceID else { throw WorkspaceActionError.groupSpaceMismatch }
        }
        for index in session.tabs.indices where candidates.contains(session.tabs[index].id) {
            session.tabs[index].groupID = groupID
        }
    }
}
