import Foundation
import RedentKit
import Testing
@testable import RedentUI

@Suite("Resume intents")
struct ResumeIntentTests {
    @Test("Resume ranks matches across spaces, groups, apps and windows and omits nonmatches")
    func ranksDestinations() throws {
        var fixture = CommandFixture()
        let space = CommandSpaceContext(id: UUID(), name: "Docs")
        let group = CommandGroupContext(id: UUID(), name: "Docs reading", spaceID: space.id,
                                        spaceName: space.name, tabIDs: [fixture.lisbonMap])
        let app = WebApp(name: "My Docs", url: try #require(URL(string: "https://example.com/")))
        let window = CommandWindowContext(id: UUID(), title: "Redocs", tabCount: 1)
        let unrelatedWindow = CommandWindowContext(id: UUID(), title: "Archive", tabCount: 1)
        fixture.context.spaces = [fixture.work, space]
        fixture.context.groups = [group, fixture.reading]
        fixture.context.webApps = [app]
        fixture.context.windows = [fixture.currentWindow, window, unrelatedWindow]

        #expect(fixture.intents("resume docs") == [
            .focusSpace(space.id), .focusTab(fixture.lisbonMap), .openWebApp(app.id), .focusWindow(window.id)
        ])
    }

    @Test("Resume excludes the current window and groups with no tabs")
    func excludesUnavailableDestinations() {
        var fixture = CommandFixture()
        fixture.context.groups = [CommandGroupContext(id: UUID(), name: "Here", spaceID: fixture.work.id,
                                                       spaceName: fixture.work.name, tabIDs: [])]

        #expect(fixture.intents("resume here").isEmpty)
        #expect(fixture.intents("resume zzz").isEmpty)
        #expect(fixture.intents("resume").isEmpty)
    }
}
