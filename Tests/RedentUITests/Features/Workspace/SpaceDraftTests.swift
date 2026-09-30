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

    @Test("A drag reports the landing index, not SwiftUI's pre-removal offset")
    func reorderTranslatesOffsets() {
        let spaces = BrowserSpace.starterSpaces
        #expect(SpaceReorder.action(spaces: spaces, from: [0], to: 3) == .moveSpace(id: spaces[0].id, toIndex: 2))
        #expect(SpaceReorder.action(spaces: spaces, from: [3], to: 0) == .moveSpace(id: spaces[3].id, toIndex: 0))
        #expect(SpaceReorder.action(spaces: spaces, from: [1], to: 2) == nil)
        #expect(SpaceReorder.action(spaces: spaces, from: [1], to: 1) == nil)
    }
}
