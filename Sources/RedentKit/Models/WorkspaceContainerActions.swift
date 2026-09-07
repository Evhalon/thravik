import Foundation

/// Container mutations. A Container is a website-data boundary, so the rules
/// here are about never leaving a tab or Space pointing at one that is gone.
extension WorkspaceState {
    /// The outer reducer's switch stays exhaustive, so a new case is a compile
    /// error there rather than a silent no-op here.
    mutating func applyContainer(_ action: WorkspaceAction) throws {
        switch action {
        case let .createContainer(name): createContainer(name: name)
        case let .renameContainer(id, name): try renameContainer(id: id, name: name)
        case let .deleteContainer(id): try deleteContainer(id: id)
        case let .moveTabToContainer(tabID, containerID):
            try moveTabToContainer(tabID: tabID, containerID: containerID)
        case let .setSpaceContainer(spaceID, containerID):
            try setSpaceContainer(spaceID: spaceID, containerID: containerID)
        default: return
        }
    }

    private mutating func createContainer(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        session.containers.append(BrowserContainer(name: trimmed))
    }

    private mutating func renameContainer(id: UUID, name: String) throws {
        guard let index = session.containers.firstIndex(where: { $0.id == id }) else {
            throw WorkspaceActionError.missingContainer(id)
        }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        session.containers[index].name = trimmed
    }

    /// Removing a Container never removes the tabs that were browsing in it:
    /// they fall back to Default, which is what the user sees them reload into.
    private mutating func deleteContainer(id: UUID) throws {
        guard session.containers.contains(where: { $0.id == id }) else {
            throw WorkspaceActionError.missingContainer(id)
        }
        guard id != BrowserContainer.defaultID else {
            throw WorkspaceActionError.cannotDeleteDefaultContainer
        }
        session.containers.removeAll { $0.id == id }
        for index in session.tabs.indices where session.tabs[index].containerID == id {
            session.tabs[index].containerID = BrowserContainer.defaultID
        }
        for index in session.spaces.indices where session.spaces[index].defaultContainerID == id {
            session.spaces[index].defaultContainerID = BrowserContainer.defaultID
        }
    }

    private mutating func moveTabToContainer(tabID: UUID, containerID: UUID) throws {
        guard let index = session.tabs.firstIndex(where: { $0.id == tabID }) else {
            throw WorkspaceActionError.missingTab(tabID)
        }
        guard session.containers.contains(where: { $0.id == containerID }) else {
            throw WorkspaceActionError.missingContainer(containerID)
        }
        session.tabs[index].containerID = containerID
    }

    private mutating func setSpaceContainer(spaceID: UUID, containerID: UUID) throws {
        guard let index = session.spaces.firstIndex(where: { $0.id == spaceID }) else {
            throw WorkspaceActionError.missingSpace(spaceID)
        }
        guard session.containers.contains(where: { $0.id == containerID }) else {
            throw WorkspaceActionError.missingContainer(containerID)
        }
        session.spaces[index].defaultContainerID = containerID
    }
}
