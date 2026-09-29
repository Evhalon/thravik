import Foundation
import RedentKit

/// The browser's own verbs in plain words: "open history", "new window",
/// "new tab swift concurrency", "reload all tabs", "reopen last tab".
enum BrowserIntents {
    private static let screens: [(words: [String], screen: BrowserScreen, title: String)] = [
        (["history"], .history, "Open History"),
        (["downloads", "download"], .downloads, "Open Downloads"),
        (["settings", "preferences", "prefs", "options"], .settings, "Open Settings"),
        (["bookmarks", "bookmark"], .bookmarks, "Open Bookmarks"),
        (["passwords", "password", "logins"], .passwords, "Open Passwords"),
        (["site data", "site settings", "privacy"], .siteData, "Open Site Data")
    ]

    static func parse(
        _ phrase: CommandPhrase, in context: CommandBarContext, searchEngine: SearchEngine
    ) -> [CommandBarResult] {
        screen(phrase) + window(phrase, context) + newTab(phrase, searchEngine) + tabs(phrase, context)
    }

    private static func screen(_ phrase: CommandPhrase) -> [CommandBarResult] {
        guard let rest = phrase.remainder(after: ["open", "show", "go to"]) else { return [] }
        return screens.filter { $0.words.contains(rest) }.map { entry in
            CommandIntentParser.row(entry.title, subtitle: "Screen", action: .showScreen(entry.screen))
        }
    }

    private static func window(_ phrase: CommandPhrase, _ context: CommandBarContext) -> [CommandBarResult] {
        let request = phrase.remainder(after: ["open", "create"]) ?? phrase.text
        if CommandPhrase(request).isOne(of: ["new private window", "private window", "new incognito window",
                                             "incognito window", "incognito"]) {
            return [CommandIntentParser.row("New Private Window", subtitle: "Window", action: .newPrivateWindow)]
        }
        if CommandPhrase(request).isOne(of: ["new window", "a new window"]) {
            return [CommandIntentParser.row("New Window", subtitle: "Window", action: .newWindow)]
        }
        return []
    }

    /// "new tab <anything>" opens that address, or searches for it.
    private static func newTab(_ phrase: CommandPhrase, _ searchEngine: SearchEngine) -> [CommandBarResult] {
        let inNewTab = phrase.text.hasSuffix(" in new tab") || phrase.text.hasSuffix(" in a new tab")
        let lowered = inNewTab
            ? phrase.text.trimming(prefix: "open ").trimming(suffix: " in new tab").trimming(suffix: " in a new tab")
            : phrase.remainder(after: ["new tab", "open new tab", "open a new tab"]) ?? ""
        let query = phrase.preservingCase(lowered)
        guard !query.isEmpty, let url = AddressResolver.resolve(query, using: searchEngine) else { return [] }
        let isSearch = url == searchEngine.searchURL(for: query)
        return [CommandIntentParser.row("Open “\(query)” in New Tab",
                                        subtitle: isSearch ? "Search \(searchEngine.label)" : url.absoluteString,
                                        action: .newTab(url))]
    }

    private static func tabs(_ phrase: CommandPhrase, _ context: CommandBarContext) -> [CommandBarResult] {
        if phrase.isOne(of: ["reload all tabs", "reload all", "refresh all tabs", "refresh all", "reload tabs"]) {
            return [CommandIntentParser.row("Reload All Tabs", subtitle: "Every open tab in this Space",
                                            action: .reloadAllTabs)]
        }
        let reopen = ["reopen last tab", "reopen closed tab", "reopen tab", "reopen last closed tab",
                      "undo close tab", "restore tab", "restore closed tab", "reopen"]
        guard context.canReopenLastClosed, phrase.isOne(of: reopen) else { return [] }
        return [CommandIntentParser.row("Reopen Last Closed Tab", subtitle: "Tab", action: .reopenLastClosed)]
    }
}
