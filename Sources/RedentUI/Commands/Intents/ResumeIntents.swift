import Foundation
import RedentKit

/// "resume Lisbon", "switch to Work", "open GitHub".
///
/// A Space already keeps its own tabs, selection and session, and restores
/// them when chosen — so resuming is choosing it. The same verbs reach tab
/// groups, saved web apps and other windows.
enum ResumeIntents {
    private static let verbs = ["resume", "continue", "switch to", "go to", "open", "restore"]

    static func parse(_ phrase: CommandPhrase, in context: CommandBarContext) -> [CommandBarResult] {
        guard let target = phrase.remainder(after: verbs), !target.isEmpty else { return [] }
        return (spaces(context) + groups(context) + apps(context) + windows(context))
            .map { (row: $0.row, score: FuzzyMatch.score(query: target, fields: [$0.name])) }
            .filter { $0.score > 0 }
            .sorted { $0.score > $1.score }
            .map(\.row)
    }

    private typealias Candidate = (name: String, row: CommandBarResult)

    private static func spaces(_ context: CommandBarContext) -> [Candidate] {
        context.spaces.map { space in
            (space.name, CommandIntentParser.row("Resume \(space.name)",
                                                 subtitle: "Space · \(tabs(space.tabIDs.count))",
                                                 action: .focusSpace(space.id)))
        }
    }

    private static func groups(_ context: CommandBarContext) -> [Candidate] {
        context.groups.compactMap { group in
            guard let first = group.tabIDs.first else { return nil }
            let place = group.spaceName.map { " in \($0)" } ?? ""
            return (group.name, CommandIntentParser.row("Resume \(group.name)",
                                                        subtitle: "Group\(place) · \(tabs(group.tabIDs.count))",
                                                        action: .focusTab(first)))
        }
    }

    private static func apps(_ context: CommandBarContext) -> [Candidate] {
        context.webApps.map { app in
            (app.name, CommandIntentParser.row("Open \(app.name)", subtitle: "App · \(app.url.host() ?? "")",
                                               action: .openWebApp(app.id)))
        }
    }

    private static func windows(_ context: CommandBarContext) -> [Candidate] {
        context.windows.filter { !$0.isCurrent }.map { window in
            (window.title, CommandIntentParser.row("Switch to “\(window.title)”",
                                                   subtitle: "Window · \(tabs(window.tabCount))",
                                                   action: .focusWindow(window.id)))
        }
    }

    private static func tabs(_ count: Int) -> String {
        count == 1 ? "1 tab" : "\(count) tabs"
    }
}
