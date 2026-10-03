import Foundation
import RedentKit

/// Stands in for the engine's website-data store: records go in, and whatever
/// Forget removes comes back out of `remaining`.
@MainActor
final class FakeSiteData: SiteDataManaging {
    /// Per context, the way real stores are: clearing one Container must not
    /// make the next one look already clean.
    private var byContext: [BrowsingContext: [SiteDataRecord]]
    let loadedContexts: [BrowsingContext]

    init(records: [SiteDataRecord] = [], contexts: [BrowsingContext] = [.container(BrowserContainer.defaultID)]) {
        self.loadedContexts = contexts
        self.byContext = Dictionary(uniqueKeysWithValues: contexts.map { ($0, records) })
    }

    var remaining: [SiteDataRecord] {
        loadedContexts.flatMap { byContext[$0] ?? [] }
    }

    func records(in context: BrowsingContext) async -> [SiteDataRecord] { byContext[context] ?? [] }

    func removeRecords(matching domain: String, in context: BrowsingContext) async -> [String] {
        let present = byContext[context] ?? []
        let matches = present.filter { $0.displayName.caseInsensitiveCompare(domain) == .orderedSame }
        byContext[context] = present.filter { $0.displayName.caseInsensitiveCompare(domain) != .orderedSame }
        return matches.map(\.displayName)
    }
}

struct SilentHistory: HistoryStoring {
    func record(url: URL, title: String, at date: Date) async {}
    func search(_ query: String, limit: Int) async -> [HistoryEntry] { [] }
    func recent(limit: Int) async -> [HistoryEntry] { [] }
    func mostVisited(limit: Int) async -> [HistoryEntry] { [] }
    func merge(_ entries: [HistoryEntry]) async {}
    func delete(_ id: UUID) async {}
    func clearAll() async {}
}

/// The smallest browser that satisfies the port: it records what Forget asked
/// it to drop, and answers everything else inertly.
@MainActor
final class FakeBrowser: BrowserControlling {
    private(set) var forgottenDomains: [String] = []
    private let forgettable: Int
    /// Seeded by the tests that need tabs to act on; empty otherwise.
    var stubTabs: [InertTab] = []
    private(set) var selectionCalls: [UUID] = []
    private(set) var closed: [UUID] = []
    private(set) var closedSets: [Set<UUID>] = []
    private(set) var openedURLs: [URL?] = []
    private(set) var duplicated: [UUID] = []

    init(forgettable: Int = 0) { self.forgettable = forgettable }

    var tabs: [any BrowserTab] { stubTabs }
    var selectedID: UUID?
    var selectedTab: (any BrowserTab)? { stubTabs.first { $0.id == selectedID } }
    var session = BrowserSession()
    var visibleTabs: [any BrowserTab] { stubTabs }
    var canReopen = false
    var canUndo = false
    var canUndoSpaces = false
    var isPrivate = false
    var signalHandler: (any PageSignalHandling)?
    var onChange: (@MainActor () -> Void)?
    var onNavigation: (@MainActor (TabSnapshot, UUID) -> Void)?

    func perform(_ action: WorkspaceAction) throws {}
    func undo() {}
    func undoSpaces() {}
    func apply(settings: BrowserSettings) {}
    func resetWorkspace() {}
    func newTab(url: URL?) -> any BrowserTab {
        openedURLs.append(url)
        return InertTab()
    }
    private(set) var backgroundURLs: [URL] = []
    func newBackgroundTab(url: URL) -> any BrowserTab {
        backgroundURLs.append(url)
        return InertTab()
    }
    func newTemporaryTab(url: URL?, expiresAt: Date?) -> any BrowserTab { InertTab() }
    func keepTab(_ id: UUID) {}
    func sweepExpiredTabs(now: Date) -> UUID? { nil }
    func close(_ id: UUID) { closed.append(id) }
    func closeTabs(_ ids: Set<UUID>) { closedSets.append(ids) }
    func closeOthers(than id: UUID) {}
    func duplicateTab(_ id: UUID) -> (any BrowserTab)? {
        guard stubTabs.contains(where: { $0.id == id }) else { return nil }
        duplicated.append(id)
        return InertTab()
    }
    func select(_ id: UUID) {
        selectionCalls.append(id)
        selectedID = id
    }
    func selectPreviouslyActiveTab() {}
    func selectNext() {}
    func selectPrevious() {}
    func move(fromOffsets: IndexSet, toOffset: Int) {}
    func applyOrder(_ ids: [UUID]) {}
    func togglePin(_ id: UUID) {}
    func reopenLastClosed() {}
    func sweepHibernation(now: Date, keeping visible: Set<UUID>) {}
    func preconnect(to url: URL) {}
    private(set) var prerendered: [URL?] = []
    func prerender(_ url: URL?) { prerendered.append(url) }

    func forgetClosedTabs(matching domain: String) -> Int {
        forgottenDomains.append(domain)
        return forgettable
    }
}
