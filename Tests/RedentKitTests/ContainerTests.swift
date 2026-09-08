import Foundation
import Testing
@testable import RedentKit

@Suite("Spaces own their Container")
struct ContainerTests {
    private func session() -> BrowserSession {
        var tab = TabSnapshot(title: "Work")
        tab.spaceID = BrowserSpace.workID
        return BrowserSession(tabs: [tab], selectedTabID: tab.id)
    }

    @Test("The Work Space keeps the Default Container, so existing cookies survive")
    func workKeepsDefault() {
        #expect(SpaceIdentity.containerID(for: BrowserSpace.workID) == BrowserContainer.defaultID)
    }

    @Test("Every Space resolves to its own Container")
    func containersAreDistinct() {
        let ids = Set(BrowserSpace.starterSpaces.map(\.containerID))
        #expect(ids.count == BrowserSpace.starterSpaces.count)
    }

    @Test("The same Space always resolves to the same Container")
    func derivationIsStable() {
        let id = UUID()
        #expect(SpaceIdentity.containerID(for: id) == SpaceIdentity.containerID(for: id))
        #expect(SpaceIdentity.containerID(for: id) != id)
    }

    @Test("A tab browses in its Space's Container")
    func tabFollowsItsSpace() {
        let session = session()
        #expect(session.tabs.first?.containerID == SpaceIdentity.containerID(for: BrowserSpace.workID))
    }

    @Test("A session written before Spaces were isolated is migrated on load")
    func legacySessionIsIsolated() throws {
        let legacy = """
        {"spaces":[{"id":"\(BrowserSpace.personalID.uuidString)","name":"Personal","icon":"square",
        "colorToken":"blue","tabIDs":[],"groupIDs":[],
        "defaultContainerID":"\(BrowserContainer.defaultID.uuidString)"}],
        "selectedSpaceID":"\(BrowserSpace.personalID.uuidString)"}
        """
        let data = Data(legacy.replacingOccurrences(of: "\n", with: "").utf8)
        let session = try JSONDecoder().decode(BrowserSession.self, from: data)
        let space = try #require(session.spaces.first)
        #expect(space.containerID != BrowserContainer.defaultID)
    }

    @Test("Moving a tab to another Space moves it to that Space's Container")
    func movingSpaceMovesContainer() throws {
        var state = WorkspaceState(session: session())
        let tabID = try #require(state.session.tabs.first?.id)
        try state.apply(.moveTab(id: tabID, toSpaceID: BrowserSpace.travelID, index: nil))
        let tab = try #require(state.session.tabs.first { $0.id == tabID })
        #expect(tab.containerID == SpaceIdentity.containerID(for: BrowserSpace.travelID))
        #expect(tab.browsingContext == .container(SpaceIdentity.containerID(for: BrowserSpace.travelID)))
    }

    @Test("A new Space browses in a Container of its own")
    func newSpaceIsIsolated() throws {
        var state = WorkspaceState(session: session())
        try state.apply(.createSpace(name: "Client"))
        let created = try #require(state.session.spaces.last)
        let others = state.session.spaces.dropLast().map(\.containerID)
        #expect(others.contains(created.containerID) == false)
    }

    @Test("Two Spaces on the same site are separate contexts")
    func isolation() {
        let work = BrowsingContext.container(SpaceIdentity.containerID(for: BrowserSpace.workID))
        let personal = BrowsingContext.container(SpaceIdentity.containerID(for: BrowserSpace.personalID))
        #expect(work != personal)
    }

    @Test("A temporary tab that cleans up owns an ephemeral context")
    func ephemeralContext() {
        let sessionID = UUID()
        var tab = TabSnapshot(title: "Private")
        tab.containerID = UUID()
        tab.lifespan = .temporary(sessionID: sessionID, expiresAt: nil, cleanupOnClose: true)
        #expect(tab.browsingContext == .ephemeral(sessionID))
    }

    @Test("A temporary tab kept in its Space still shares that Space's Container")
    func retainedTemporaryContext() {
        let containerID = UUID()
        var tab = TabSnapshot(title: "Temp")
        tab.containerID = containerID
        tab.lifespan = .temporary(sessionID: UUID(), expiresAt: nil, cleanupOnClose: false)
        #expect(tab.browsingContext == .container(containerID))
    }
}
