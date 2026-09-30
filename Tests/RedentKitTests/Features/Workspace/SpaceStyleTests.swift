import Foundation
import Testing
@testable import RedentKit

@Suite("Space style and order")
struct SpaceStyleTests {
    private let look = SpaceIdentity.Look(icon: "globe", colorToken: "lime")

    @Test("A Space created with a look keeps it")
    func createWithLook() throws {
        var state = WorkspaceState()
        try state.apply(.createSpace(name: "  Studio ", look: look))
        let created = try #require(state.session.spaces.last)
        #expect(created.name == "Studio")
        #expect(SpaceIdentity.look(id: created.id, icon: created.icon, colorToken: created.colorToken) == look)
    }

    @Test("A starter Space can be restyled past its preset")
    func restyleStarter() throws {
        var state = WorkspaceState()
        try state.apply(.setSpaceLook(id: BrowserSpace.workID, look: look))
        let work = try #require(state.session.spaces.first { $0.id == BrowserSpace.workID })
        #expect(SpaceIdentity.look(id: work.id, icon: work.icon, colorToken: work.colorToken) == look)
    }

    @Test("Restyling a missing Space throws")
    func restyleMissing() {
        var state = WorkspaceState()
        #expect(throws: WorkspaceActionError.self) {
            try state.apply(.setSpaceLook(id: UUID(), look: look))
        }
    }

    @Test("Moving a Space lands it at the final index, both directions")
    func moveSpace() throws {
        var state = WorkspaceState()
        try state.apply(.moveSpace(id: BrowserSpace.workID, toIndex: 2))
        #expect(state.session.spaces.map(\.id) == [BrowserSpace.personalID, BrowserSpace.researchID,
                                                     BrowserSpace.workID, BrowserSpace.travelID])
        try state.apply(.moveSpace(id: BrowserSpace.travelID, toIndex: 0))
        #expect(state.session.spaces.first?.id == BrowserSpace.travelID)
    }

    @Test("An out-of-range move clamps to the ends")
    func moveClamps() throws {
        var state = WorkspaceState()
        try state.apply(.moveSpace(id: BrowserSpace.workID, toIndex: 99))
        #expect(state.session.spaces.last?.id == BrowserSpace.workID)
        try state.apply(.moveSpace(id: BrowserSpace.workID, toIndex: -3))
        #expect(state.session.spaces.first?.id == BrowserSpace.workID)
    }

    @Test("Reordering keeps the selected Space selected")
    func moveKeepsSelection() throws {
        var state = WorkspaceState()
        try state.apply(.selectSpace(id: BrowserSpace.researchID))
        try state.apply(.moveSpace(id: BrowserSpace.researchID, toIndex: 0))
        #expect(state.session.selectedSpaceID == BrowserSpace.researchID)
    }
}
