import Foundation
import RedentKit

/// "close all tabs", "close other tabs", "close youtube tabs".
///
/// Closing is undoable (⌥⌘Z), but a sweep still names what it will take and
/// never reaches for a pinned tab unless the user named the site it shows.
enum CloseIntents {
    private static let verbs = ["close", "shut"]
    /// Words that belong to the plain Close Tab / Close Window commands.
    private static let reserved = ["tab", "this tab", "current tab", "window", "this window",
                                   "all tabs", "other tabs", "tabs"]

    static func parse(_ phrase: CommandPhrase, in context: CommandBarContext) -> [CommandBarResult] {
        guard let rest = phrase.remainder(after: verbs), !rest.isEmpty else { return [] }
        let words = CommandPhrase(rest)
        if words.isOne(of: ["all", "all tabs", "everything"]) { return allInSpace(context) }
        if words.isOne(of: ["other tabs", "others", "all other tabs", "the other tabs"]) { return others(context) }
        guard !words.isTyping(toward: reserved) else { return [] }
        let term = rest.trimming(prefix: "all ").trimming(prefix: "tabs from ").trimming(prefix: "tabs of ")
            .trimming(suffix: " tabs").trimming(suffix: " tab")
        guard term.count >= 2 else { return [] }
        return matching(term, context)
    }

    private static func allInSpace(_ context: CommandBarContext) -> [CommandBarResult] {
        let ids = spaceTabs(context).filter { !$0.isPinned }.map(\.id)
        guard !ids.isEmpty else { return [] }
        let space = context.spaces.first { $0.id == context.selectedSpaceID }?.name ?? "this Space"
        return [CommandIntentParser.row("Close All \(tabCount(ids.count)) in \(space)",
                                        subtitle: "Pinned tabs stay · ⌥⌘Z to undo",
                                        action: .closeTabs(Set(ids)))]
    }

    private static func others(_ context: CommandBarContext) -> [CommandBarResult] {
        let ids = spaceTabs(context).filter { !$0.isPinned && $0.id != context.selectedTabID }.map(\.id)
        guard !ids.isEmpty else { return [] }
        return [CommandIntentParser.row("Close \(tabCount(ids.count, other: true))",
                                        subtitle: "Keeps the current and pinned tabs · ⌥⌘Z to undo",
                                        action: .closeTabs(Set(ids)))]
    }

    /// Closing is where a loose match does harm, so a site is matched by its
    /// host or a real piece of its title — never by letters in order.
    private static func matching(_ term: String, _ context: CommandBarContext) -> [CommandBarResult] {
        let hits = context.tabs.filter { tab in
            let host = tab.url?.host() ?? ""
            return FuzzyMatch.score(term, in: host) >= 2 || FuzzyMatch.score(term, in: tab.title) >= 2
        }
        guard !hits.isEmpty else { return [] }
        let names = hits.prefix(3).map { $0.title.isEmpty ? "Untitled" : $0.title }
        let more = hits.count > 3 ? " and \(hits.count - 3) more" : ""
        return [CommandIntentParser.row("Close \(hits.count) “\(term)” \(hits.count == 1 ? "Tab" : "Tabs")",
                                        subtitle: names.joined(separator: ", ") + more,
                                        action: .closeTabs(Set(hits.map(\.id))))]
    }

    private static func spaceTabs(_ context: CommandBarContext) -> [CommandTabContext] {
        context.tabs.filter { $0.spaceID == context.selectedSpaceID || context.selectedSpaceID == nil }
    }

    private static func tabCount(_ count: Int, other: Bool = false) -> String {
        let noun = count == 1 ? "Tab" : "Tabs"
        return other ? "\(count) Other \(noun)" : "\(count) \(noun)"
    }
}
