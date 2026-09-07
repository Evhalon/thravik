import Foundation

public enum WorkspaceAction: Sendable, Hashable, Codable {
    case createSpace(name: String)
    case renameSpace(id: UUID, name: String)
    case deleteSpace(id: UUID)
    case selectSpace(id: UUID)
    case selectTab(id: UUID)
    case moveTab(id: UUID, toSpaceID: UUID, index: Int?)
    case setPinned(id: UUID, isPinned: Bool)
    case createGroup(spaceID: UUID, name: String)
    case createGroupWithTabs(spaceID: UUID, name: String, tabIDs: [UUID])
    case renameGroup(id: UUID, name: String)
    case deleteGroup(id: UUID)
    case moveTabToGroup(tabID: UUID, groupID: UUID?)
    case groupTabs(groupID: UUID, tabIDs: [UUID])
    case createContainer(name: String)
    case renameContainer(id: UUID, name: String)
    case deleteContainer(id: UUID)
    case moveTabToContainer(tabID: UUID, containerID: UUID)
    case setSpaceContainer(spaceID: UUID, containerID: UUID)
}

public enum WorkspaceActionError: Error, Equatable, Sendable {
    case missingSpace(UUID)
    case missingTab(UUID)
    case missingGroup(UUID)
    case cannotDeleteLastSpace
    case groupSpaceMismatch
    case missingContainer(UUID)
    case cannotDeleteDefaultContainer
}
