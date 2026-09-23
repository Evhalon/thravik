import Foundation
import RedentKit

/// Rows for what the window already holds: tabs, Spaces, groups, windows and
/// saved web apps. Matching is loose on names and titles, strict on URLs.
enum CommandEntityRows {
    static func rows(matching query: String, in context: CommandBarContext) -> [CommandBarResult] {
        tabs(matching: query, context) + webApps(matching: query, context) + spaces(matching: query, context)
            + groups(matching: query, context) + windows(matching: query, context)
    }

    static func tabs(matching query: String, _ context: CommandBarContext) -> [CommandBarResult] {
        context.tabs.filter {
            FuzzyMatch.matches(query, fields: [$0.title, $0.url?.host(), $0.spaceName], exact: [$0.url?.absoluteString])
        }.map(tabRow)
    }

    static func tabRow(_ tab: CommandTabContext) -> CommandBarResult {
        let subtitle = [tab.url?.absoluteString, tab.spaceName].compactMap { $0 }.joined(separator: " · ")
        var row = CommandBarResult(id: "tab:\(tab.id)", title: tab.title.isEmpty ? "Untitled Tab" : tab.title,
                                   subtitle: subtitle, source: .tab, action: .focusTab(tab.id))
        row.faviconData = tab.faviconData
        row.faviconHost = tab.url?.host()
        return row
    }

    static func appRow(_ app: WebApp) -> CommandBarResult {
        var row = CommandBarResult(id: "app:\(app.id)", title: app.name,
                                   subtitle: "App · \(app.url.host() ?? app.url.absoluteString)",
                                   source: .webApp, action: .openWebApp(app.id))
        row.faviconData = app.faviconData
        row.faviconHost = app.url.host()
        return row
    }

    private static func webApps(matching query: String, _ context: CommandBarContext) -> [CommandBarResult] {
        context.webApps.filter { FuzzyMatch.matches(query, fields: [$0.name, $0.url.host()]) }.map(appRow)
    }

    private static func spaces(matching query: String, _ context: CommandBarContext) -> [CommandBarResult] {
        context.spaces.filter { FuzzyMatch.matches(query, fields: [$0.name]) }.map { space in
            CommandBarResult(id: "space:\(space.id)", title: space.name,
                             subtitle: "Space · \(count(space.tabIDs.count, "tab"))", source: .space,
                             action: .focusSpace(space.id))
        }
    }

    /// A group is resumed by showing its first tab, which also brings its
    /// Space forward.
    private static func groups(matching query: String, _ context: CommandBarContext) -> [CommandBarResult] {
        context.groups.filter { FuzzyMatch.matches(query, fields: [$0.name]) }.compactMap { group in
            guard let first = group.tabIDs.first else { return nil }
            let place = group.spaceName.map { " in \($0)" } ?? ""
            return CommandBarResult(id: "group:\(group.id)", title: group.name,
                                    subtitle: "Group\(place) · \(count(group.tabIDs.count, "tab"))",
                                    source: .group, action: .focusTab(first))
        }
    }

    private static func windows(matching query: String, _ context: CommandBarContext) -> [CommandBarResult] {
        context.windows.filter { !$0.isCurrent && FuzzyMatch.matches(query, fields: [$0.title, "window"]) }
            .map { window in
                let kind = window.isPrivate ? "Private Window" : "Window"
                return CommandBarResult(id: "window:\(window.id)", title: window.title,
                                        subtitle: "\(kind) · \(count(window.tabCount, "tab"))",
                                        source: .window, action: .focusWindow(window.id))
            }
    }

    private static func count(_ value: Int, _ noun: String) -> String {
        value == 1 ? "1 \(noun)" : "\(value) \(noun)s"
    }
}
