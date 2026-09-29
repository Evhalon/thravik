import Foundation
import Testing
@testable import RedentKit

@Suite("Tab group labels")
struct TabGroupLabelTests {
    @Test("Quotes, punctuation and extra words are trimmed away")
    func trimsModelNoise() {
        #expect(TabGroupLabel.sanitized("  \"Code review\".\n") == "Code review")
        #expect(TabGroupLabel.sanitized("Viaggio a Lisbona in agosto") == "Viaggio a Lisbona")
    }

    @Test("Nothing usable keeps the site name")
    func rejectsUnusable() {
        #expect(TabGroupLabel.sanitized("  ...  ") == nil)
        #expect(TabGroupLabel.sanitized("Supercalifragilisticexpialidocious") == nil)
    }

    @Test("The prompt shows only titles and sites, and at most the limit")
    func promptIsBounded() {
        let pages = (1...10).map { TabGroupPage(title: "Page \($0)", host: "example.com") }
        let prompt = TabGroupLabel.prompt(for: pages, limit: 3)
        let lines = prompt.split(separator: "\n")
        #expect(lines.first.map(String.init) == TabGroupLabel.promptLeadIn)
        #expect(lines.dropFirst() == ["- Page 1 (example.com)", "- Page 2 (example.com)", "- Page 3 (example.com)"])
    }

    @Test("Short titles in another language still read as a language")
    func promptLeadsWithASentence() {
        let pages = [TabGroupPage(title: "Voli per Lisbona", host: "google.com")]
        #expect(TabGroupLabel.prompt(for: pages).hasPrefix(TabGroupLabel.promptLeadIn + "\n"))
    }

    @Test("Groups saved before automatic names existed still load")
    func legacyGroupDecodes() throws {
        let group = BrowserGroup(spaceID: BrowserSpace.workID, name: "Trip")
        let json = """
            {"id":"\(group.id)","spaceID":"\(group.spaceID)","name":"Trip","colorToken":"blue","tabIDs":[]}
            """
        let decoded = try JSONDecoder().decode(BrowserGroup.self, from: Data(json.utf8))
        #expect(decoded == group)
        #expect(!decoded.isNameAutomatic)
    }

    @Test("Renaming a group makes its name the user's")
    func renameClearsAutomatic() throws {
        let tab = TabSnapshot(title: "Only", spaceID: BrowserSpace.workID)
        var state = WorkspaceState(session: BrowserSession(tabs: [tab], selectedTabID: tab.id))
        try state.apply(.createGroupWithTabs(spaceID: BrowserSpace.workID, name: "example.com", tabIDs: [tab.id]))
        var session = state.session
        session.groups[0].isNameAutomatic = true
        state = WorkspaceState(session: session)
        let id = try #require(state.session.groups.first?.id)
        try state.apply(.renameGroup(id: id, name: "Trip"))
        #expect(state.session.groups.first?.isNameAutomatic == false)
    }
}
