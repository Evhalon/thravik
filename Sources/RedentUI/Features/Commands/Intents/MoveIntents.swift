import Foundation
import RedentKit

/// "move this tab to Work", "move tab to new window", "send tab to Reading".
///
/// With no destination typed yet, every place the tab could go is listed, so
/// "Move Tab to…" works as a menu the keyboard can walk.
enum MoveIntents {
    private static let verbs = ["move this tab to", "move current tab to", "move tab to", "move to",
                                "send this tab to", "send tab to", "move this tab", "move tab"]

    static func parse(_ phrase: CommandPhrase, in context: CommandBarContext) -> [CommandBarResult] {
        guard let destination = phrase.remainder(after: verbs), let tab = context.selectedTab else { return [] }
        let candidates = spaces(for: tab, context) + groups(for: tab, context) + windows(for: tab, context)
        guard !destination.isEmpty else { return candidates.map(\.row) }
        return candidates
            .map { (row: $0.row, score: FuzzyMatch.score(query: destination, fields: [$0.name])) }
            .filter { $0.score > 0 }
            .sorted { $0.score > $1.score }
            .map(\.row)
    }

    private typealias Candidate = (name: String, row: CommandBarResult)

    private static func spaces(for tab: CommandTabContext, _ context: CommandBarContext) -> [Candidate] {
        context.spaces.filter { $0.id != tab.spaceID }.map { space in
            (space.name, CommandIntentParser.row("Move Tab to \(space.name)", subtitle: "Space",
                                                 action: .moveTab(tabID: tab.id, spaceID: space.id)))
        }
    }

    private static func groups(for tab: CommandTabContext, _ context: CommandBarContext) -> [Candidate] {
        context.groups.filter { $0.id != tab.groupID }.map { group in
            let place = group.spaceName.map { "Group in \($0)" } ?? "Group"
            return (group.name, CommandIntentParser.row("Move Tab to \(group.name)", subtitle: place,
                                                        action: .moveTabToGroup(tabID: tab.id, groupID: group.id)))
        }
    }

    /// A page never crosses the private boundary: moving it would carry its
    /// session into a window that keeps history, or the other way round.
    private static func windows(for tab: CommandTabContext, _ context: CommandBarContext) -> [Candidate] {
        let others = context.windows.filter { !$0.isCurrent && $0.isPrivate == context.isPrivate }
        let existing: [Candidate] = others.map { window in
            ("window \(window.title)",
             CommandIntentParser.row("Move Tab to Window “\(window.title)”",
                                     subtitle: "Window · \(window.tabCount) tabs",
                                     action: .moveTabToWindow(tabID: tab.id, windowID: window.id)))
        }
        let fresh: Candidate = ("new window", CommandIntentParser.row(
            "Move Tab to New Window", subtitle: "Window",
            action: .moveTabToWindow(tabID: tab.id, windowID: nil)))
        return existing + [fresh]
    }
}
