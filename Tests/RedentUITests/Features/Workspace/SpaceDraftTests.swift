import Foundation
import RedentKit
import Testing
@testable import RedentUI

@Suite("Space creation funnel")
struct SpaceDraftTests {
    private let look = SpaceIdentity.Look(icon: "globe", colorToken: "lime")

    @Test("The funnel will not leave the name step without a name")
    func nameGatesAdvance() {
        var draft = SpaceDraft.new()
        draft.name = "   "
        draft.advance()
        #expect(draft.step == .name)
        #expect(!draft.canReach(.icon))
        draft.name = "Studio"
        draft.advance()
        draft.advance()
        #expect(draft.step == .icon)
        #expect(draft.isLastStep)
        draft.advance()
        #expect(draft.step == .icon)
    }

    @Test("Retreating stops at the first step")
    func retreatStops() {
        var draft = SpaceDraft.new()
        draft.name = "Studio"
        draft.advance()
        draft.retreat()
        draft.retreat()
        #expect(draft.step == .name)
    }

    @Test("A new draft commits one create carrying the chosen look")
    func newCommits() {
        var draft = SpaceDraft.new()
        draft.name = " Studio "
        draft.look = look
        #expect(draft.actions == [.createSpace(name: "Studio", look: look)])
    }

    @Test("An untouched edit asks for nothing")
    func untouchedEdit() {
        let draft = SpaceDraft.editing(BrowserSpace(name: "Studio"))
        #expect(draft.actions.isEmpty)
    }

    @Test("An edit commits only the fields that changed")
    func editCommitsChanges() {
        let space = BrowserSpace(name: "Studio")
        var draft = SpaceDraft.editing(space)
        draft.look = look
        #expect(draft.actions == [.setSpaceLook(id: space.id, look: look)])
        draft.name = "Lab"
        #expect(draft.actions == [.renameSpace(id: space.id, name: "Lab"), .setSpaceLook(id: space.id, look: look)])
    }

    @Test("A drag lands on the row the pointer travelled to, clamped to the list")
    func reorderLandsOnTravelledRow() {
        #expect(SpaceReorder.landing(origin: 0, travel: 100, pitch: 48, count: 4) == 2)
        #expect(SpaceReorder.landing(origin: 3, travel: -500, pitch: 48, count: 4) == 0)
        #expect(SpaceReorder.landing(origin: 1, travel: 20, pitch: 48, count: 4) == 1)
        #expect(SpaceReorder.landing(origin: 2, travel: 900, pitch: 48, count: 4) == 3)
    }

    @Test("Rows between origin and landing slide toward the gap")
    func reorderShiftsNeighbours() {
        #expect(SpaceReorder.shift(for: 1, origin: 0, landing: 2, pitch: 48) == -48)
        #expect(SpaceReorder.shift(for: 3, origin: 0, landing: 2, pitch: 48) == 0)
        #expect(SpaceReorder.shift(for: 1, origin: 3, landing: 1, pitch: 48) == 48)
        #expect(SpaceReorder.shift(for: 0, origin: 3, landing: 1, pitch: 48) == 0)
    }

    @Test("A drop moves the Space only when it lands somewhere new")
    func reorderAction() {
        let spaces = BrowserSpace.starterSpaces
        #expect(SpaceReorder.action(spaces: spaces, origin: 0, landing: 2) == .moveSpace(id: spaces[0].id, toIndex: 2))
        #expect(SpaceReorder.action(spaces: spaces, origin: 3, landing: 0) == .moveSpace(id: spaces[3].id, toIndex: 0))
        #expect(SpaceReorder.action(spaces: spaces, origin: 1, landing: 1) == nil)
    }
}
