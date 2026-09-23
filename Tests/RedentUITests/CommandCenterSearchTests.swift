import Foundation
import RedentKit
import Testing
@testable import RedentUI

@MainActor
@Suite("Command Center search")
struct CommandCenterSearchTests {
    private let fixture = CommandFixture()

    private func search(_ query: String) async -> CommandBarModel {
        await search(query, context: fixture.context)
    }

    private func search(_ query: String, context: CommandBarContext) async -> CommandBarModel {
        var configuration = CommandBarModel.Configuration(history: SilentHistory(), bookmarks: InertBookmarkStore())
        configuration.context = context
        let model = CommandBarModel(configuration: configuration)
        model.query = query
        await model.searchInFlight?.value
        return model
    }

    @Test("“git” puts the GitHub tab first, though its title is about a pull request")
    func gitFindsGitHub() async {
        let model = await search("git")
        #expect(model.rows.first?.action == .focusTab(fixture.github))
    }

    @Test("An address opens directly; anything else searches")
    func addressOrSearch() async throws {
        let address = await search("github.com")
        #expect(address.rows.first?.source == .directURL)
        let search = await search("best mechanical keyboards")
        let expected = try #require(SearchEngine.duckduckgo.searchURL(for: "best mechanical keyboards"))
        #expect(search.rows.first?.action == .navigate(expected))
    }

    @Test("A plain sentence leads with what it asks for")
    func intentLeads() async {
        let model = await search("close youtube tabs")
        #expect(model.rows.first?.action == .closeTabs([fixture.youtube, fixture.pinnedYouTube]))
    }

    @Test("“Move Tab to…” asks for its destination instead of running")
    func completionFillsField() async throws {
        let model = await search("move tab to…")
        let prompt = try #require(model.rows.first { $0.completion != nil })
        let sink = RecordedActions()
        model.onExecute = { sink.actions.append($0) }

        let finished = await model.execute(prompt)
        await model.searchInFlight?.value

        #expect(!finished)
        #expect(sink.actions.isEmpty)
        #expect(model.query == "move tab to ")
        #expect(model.rows.contains { $0.title == "Move Tab to New Window" })
    }

    @Test("Before typing: the other tabs here, then actions — not the tab already in front")
    func home() async {
        let model = await search("")
        #expect(model.rows.first?.source == .tab)
        #expect(!model.rows.contains { $0.action == .focusTab(fixture.github) })
        #expect(!model.rows.contains { $0.action == .focusTab(fixture.lisbonMap) })
        #expect(model.rows.contains { $0.source == .command })
    }

    @Test("A window that closed since the row was drawn is not focused")
    func staleWindow() async throws {
        let model = await search("docs")
        let row = try #require(model.rows.first { $0.action == .focusWindow(fixture.otherWindow.id) })
        let sink = RecordedActions()
        model.onExecute = { sink.actions.append($0) }
        var closed = fixture.context
        closed.windows = [fixture.currentWindow]
        model.updateContext(closed)

        await model.execute(row)

        #expect(sink.actions.isEmpty)
    }
}

@MainActor
private final class RecordedActions {
    var actions: [BrowserAction] = []
}
