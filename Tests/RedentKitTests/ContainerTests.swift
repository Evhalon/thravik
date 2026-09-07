import Foundation
import Testing
@testable import RedentKit

@Suite("Containers")
struct ContainerTests {
    private func session() -> BrowserSession {
        var tab = TabSnapshot(title: "Work")
        tab.spaceID = BrowserSpace.workID
        return BrowserSession(tabs: [tab], selectedTabID: tab.id)
    }

    @Test("A tab without a Container browses in Default")
    func defaultContext() {
        let tab = TabSnapshot(title: "Plain")
        #expect(tab.browsingContext == .container(BrowserContainer.defaultID))
    }

    @Test("A temporary tab that cleans up owns an ephemeral context")
    func ephemeralContext() {
        let sessionID = UUID()
        var tab = TabSnapshot(title: "Private")
        tab.containerID = UUID()
        tab.lifespan = .temporary(sessionID: sessionID, expiresAt: nil, cleanupOnClose: true)
        #expect(tab.browsingContext == .ephemeral(sessionID))
    }

    @Test("A temporary tab kept in its Container still shares that Container")
    func retainedTemporaryContext() {
        let containerID = UUID()
        var tab = TabSnapshot(title: "Temp")
        tab.containerID = containerID
        tab.lifespan = .temporary(sessionID: UUID(), expiresAt: nil, cleanupOnClose: false)
        #expect(tab.browsingContext == .container(containerID))
    }

    @Test("Moving a tab into a Container that does not exist is rejected")
    func unknownContainer() throws {
        var state = WorkspaceState(session: session())
        let tabID = try #require(state.session.tabs.first?.id)
        #expect(throws: WorkspaceActionError.self) {
            try state.apply(.moveTabToContainer(tabID: tabID, containerID: UUID()))
        }
    }

    @Test("Deleting a Container returns its tabs and Spaces to Default")
    func deletionFallsBack() throws {
        var state = WorkspaceState(session: session())
        try state.apply(.createContainer(name: "Second account"))
        let container = try #require(state.session.containers.last?.id)
        let tabID = try #require(state.session.tabs.first?.id)
        try state.apply(.moveTabToContainer(tabID: tabID, containerID: container))
        try state.apply(.setSpaceContainer(spaceID: BrowserSpace.workID, containerID: container))

        try state.apply(.deleteContainer(id: container))
        #expect(state.session.containers.contains { $0.id == container } == false)
        #expect(state.session.tabs.first?.containerID == BrowserContainer.defaultID)
        #expect(state.session.spaces.first { $0.id == BrowserSpace.workID }?
            .defaultContainerID == BrowserContainer.defaultID)
    }

    @Test("Default cannot be deleted")
    func defaultIsPermanent() {
        var state = WorkspaceState(session: session())
        #expect(throws: WorkspaceActionError.cannotDeleteDefaultContainer) {
            try state.apply(.deleteContainer(id: BrowserContainer.defaultID))
        }
    }

    @Test("Two Containers on the same site are separate contexts")
    func isolation() throws {
        var state = WorkspaceState(session: session())
        try state.apply(.createContainer(name: "Personal"))
        try state.apply(.createContainer(name: "Work account"))
        let first = try #require(state.session.containers.dropLast().last?.id)
        let second = try #require(state.session.containers.last?.id)
        #expect(BrowsingContext.container(first) != BrowsingContext.container(second))
    }
}
