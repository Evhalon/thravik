import Foundation

public enum WorkspaceAction: Sendable, Hashable, Codable {
    /// Nil look derives one from the new Space's id.
    case createSpace(name: String, look: SpaceIdentity.Look?)
    case renameSpace(id: UUID, name: String)
    case setSpaceLook(id: UUID, look: SpaceIdentity.Look)
    /// `index` is the Space's position once the move is done.
    case moveSpace(id: UUID, toIndex: Int)
    case deleteSpace(id: UUID)
    case selectSpace(id: UUID)
    case selectTab(id: UUID)
    case moveTab(id: UUID, toSpaceID: UUID, index: Int?)
    case setPinned(id: UUID, isPinned: Bool)
    /// Nil or blank restores the page's own title.
    case renameTab(id: UUID, title: String?)
    case setPinnedURL(id: UUID, url: URL?)
    case createGroup(spaceID: UUID, name: String)
    case createGroupWithTabs(spaceID: UUID, name: String, tabIDs: [UUID])
    case renameGroup(id: UUID, name: String)
    case deleteGroup(id: UUID)
    case moveTabToGroup(tabID: UUID, groupID: UUID?)
    case groupTabs(groupID: UUID, tabIDs: [UUID])
    /// Keeps a tab out of, or returns it to, its site's automatic cluster.
    case setApartFromSite(tabID: UUID, isApart: Bool)
}

public enum WorkspaceActionError: Error, Equatable, Sendable {
    case missingSpace(UUID)
    case missingTab(UUID)
    case missingGroup(UUID)
    case cannotDeleteLastSpace
    case groupSpaceMismatch
}
