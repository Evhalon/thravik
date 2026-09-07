import Foundation
import Testing
@testable import RedentKit

@Suite("Tab close selection")
struct TabCloseSelectionTests {
    @Test("Closing the last row selects the one above")
    func lastSelectsAbove() {
        let ids = [UUID(), UUID(), UUID()]
        #expect(TabCloseSelection.afterClosing(ids[2], in: ids) == ids[1])
        #expect(TabCloseSelection.afterClosing(ids[1], in: ids) == ids[0])
    }

    @Test("Closing the top row selects the one that was beneath")
    func topSelectsBelow() {
        let ids = [UUID(), UUID(), UUID()]
        #expect(TabCloseSelection.afterClosing(ids[0], in: ids) == ids[1])
    }

    @Test("Closing the only tab selects nothing")
    func lastRemainingClears() {
        let id = UUID()
        #expect(TabCloseSelection.afterClosing(id, in: [id]) == nil)
    }

    @Test("A cluster child closes onto its parent")
    func childSelectsParent() {
        var parent = TabSnapshot(title: "Parent", spaceID: BrowserSpace.workID)
        var child = TabSnapshot(title: "Child", spaceID: BrowserSpace.workID)
        child.parentTabID = parent.id
        let groupID = UUID()
        parent.groupID = groupID
        child.groupID = groupID
        let group = BrowserGroup(id: groupID, spaceID: BrowserSpace.workID, name: parent.title)
        let outline = SidebarOutline(tabs: [parent, child], groups: [group], spaceID: BrowserSpace.workID)
        #expect(outline.tabIDs == [parent.id, child.id])
        #expect(TabCloseSelection.afterClosing(child.id, in: outline.tabIDs) == parent.id)
    }
}
