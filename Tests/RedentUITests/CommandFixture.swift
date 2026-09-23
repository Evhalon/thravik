import Foundation
import RedentKit
@testable import RedentUI

/// A window with enough in it to read commands against: a few sites across
/// two Spaces, a group, another window, and a private one.
struct CommandFixture {
    let work = CommandSpaceContext(id: UUID(), name: "Work", isCurrent: true)
    let lisbon = CommandSpaceContext(id: UUID(), name: "Lisbon")
    let reading: CommandGroupContext
    let github = UUID()
    let youtube = UUID()
    let pinnedYouTube = UUID()
    let linear = UUID()
    let lisbonMap = UUID()
    let otherWindow = CommandWindowContext(id: UUID(), title: "Docs", tabCount: 3)
    let privateWindow = CommandWindowContext(id: UUID(), title: "Secret", tabCount: 1, flags: .init(isPrivate: true))
    let currentWindow = CommandWindowContext(id: UUID(), title: "Here", tabCount: 5, flags: .init(isCurrent: true))
    var context: CommandBarContext

    init() {
        reading = CommandGroupContext(id: UUID(), name: "Reading", spaceID: lisbon.id, spaceName: "Lisbon", tabIDs: [lisbonMap])
        let tabs = [
            Self.tab(github, "Pull request #182 — OnePanel — GitHub", "https://github.com/acme/onepanel/pull/182", work),
            Self.tab(youtube, "Lo-fi beats - YouTube", "https://www.youtube.com/watch?v=1", work),
            Self.tab(pinnedYouTube, "Talks - YouTube", "https://www.youtube.com/watch?v=2", work, pinned: true),
            Self.tab(linear, "Linear — Project", "https://linear.app/acme/project", work),
            Self.tab(lisbonMap, "Lisbon map", "https://maps.example/lisbon", lisbon)
        ]
        context = CommandBarContext(tabs: tabs, spaces: [work, lisbon], selectedTabID: github,
                                    selectedSpaceID: work.id, canReopenLastClosed: true)
        context.groups = [reading]
        context.windows = [currentWindow, otherWindow, privateWindow]
    }

    private static func tab(
        _ id: UUID, _ title: String, _ address: String, _ space: CommandSpaceContext, pinned: Bool = false
    ) -> CommandTabContext {
        CommandTabContext(id: id, title: title, values: .init(
            url: URL(string: address), isPinned: pinned, spaceID: space.id, spaceName: space.name))
    }

    func intents(_ query: String) -> [BrowserAction] {
        CommandIntentParser.intents(for: query, in: context, searchEngine: .duckduckgo).compactMap(\.action)
    }
}
