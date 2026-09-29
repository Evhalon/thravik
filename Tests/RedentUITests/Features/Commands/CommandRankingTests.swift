import Foundation
import RedentKit
import Testing
@testable import RedentUI

@Suite("Command Bar ranking")
struct CommandRankingTests {
    private let search = CommandBarResult(id: "search", title: "q", subtitle: "Search", source: .search)

    private func row(_ title: String, _ source: CommandResultSource, subtitle: String = "") -> CommandBarResult {
        CommandBarResult(id: "\(source):\(title)", title: title, subtitle: subtitle, source: source)
    }

    @Test("An exact command beats pages that merely mention it")
    func exactCommandFirst() {
        let rows = [row("Tab groups explained", .history), row("New Tab", .command)]
        let ordered = CommandRanking.order(rows, direct: nil, search: search, query: "new tab")
        #expect(ordered.first?.title == "New Tab")
        #expect(ordered.last?.source == .search)
    }

    @Test("An open tab beats a visit with an equally good match")
    func openTabBeatsHistory() {
        let rows = [row("GitHub", .history), row("GitHub", .tab)]
        let ordered = CommandRanking.order(rows, direct: nil, search: search, query: "git")
        #expect(ordered.first?.source == .tab)
    }

    @Test("A host prefix counts for tabs, but a command's label is not a host")
    func hostPrefixOnlyForPages() {
        let rows = [row("Reload Page", .command, subtitle: "Command"),
                    row("Pull requests", .tab, subtitle: "https://github.com/pulls")]
        let ordered = CommandRanking.order(rows, direct: nil, search: search, query: "git")
        #expect(ordered.first?.source == .tab)
        #expect(CommandRanking.score(rows[0], needle: "com") < 3)
    }

    @Test("Nothing matching well puts the web search first")
    func weakMatchesSearch() {
        let rows = [row("Rome travel notes", .history)]
        let ordered = CommandRanking.order(rows, direct: nil, search: search, query: "weather in rome")
        #expect(ordered.first?.source == .search)
    }

    @Test("A typed address always leads")
    func directLeads() {
        let direct = row("https://example.com", .directURL)
        let ordered = CommandRanking.order([row("Example", .history)], direct: direct, search: search, query: "example.com")
        #expect(ordered.first?.source == .directURL)
    }
}
