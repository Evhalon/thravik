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

    init(forgettable: Int = 0) { self.forgettable = forgettable }

    var tabs: [any BrowserTab] { [] }
    var selectedID: UUID?
    var selectedTab: (any BrowserTab)? { nil }
    var session = BrowserSession()
    var visibleTabs: [any BrowserTab] { [] }
    var canReopen = false
    var canUndo = false
    var signalHandler: (any PageSignalHandling)?
    var onChange: (@MainActor () -> Void)?
    var onNavigation: (@MainActor (TabSnapshot, UUID) -> Void)?

    func perform(_ action: WorkspaceAction) throws {}
    func undo() {}
    func apply(settings: BrowserSettings) {}
    func resetWorkspace() {}
    func newTab(url: URL?) -> any BrowserTab { InertTab() }
    func newTemporaryTab(url: URL?, expiresAt: Date?) -> any BrowserTab { InertTab() }
    func keepTab(_ id: UUID) {}
    func sweepExpiredTabs(now: Date) -> UUID? { nil }
    func close(_ id: UUID) {}
    func closeOthers(than id: UUID) {}
    func select(_ id: UUID) {}
    func selectNext() {}
    func selectPrevious() {}
    func move(fromOffsets: IndexSet, toOffset: Int) {}
    func applyOrder(_ ids: [UUID]) {}
    func togglePin(_ id: UUID) {}
    func reopenLastClosed() {}
    func sweepHibernation(now: Date, keeping visible: Set<UUID>) {}

    func forgetClosedTabs(matching domain: String) -> Int {
        forgottenDomains.append(domain)
        return forgettable
    }
}

@MainActor
final class InertTab: BrowserTab {
    let id = UUID()
    var snapshot = TabSnapshot()
    var title = ""
    var url: URL?
    var progress: Double = 0
    var isLoading = false
    var canGoBack = false
    var canGoForward = false
    var isHibernated = true
    var isPinned = false
    var origin: Origin? { nil }
    func load(_ url: URL) {}
    func goBack() {}
    func goForward() {}
    func reload() {}
    func stopLoading() {}
    func fillCredential(username: String, password: String) async {}
    func fillOTPCode(_ code: String) async {}
    func hibernate() {}
    var timeline: [NavigationEntry] { [] }
    func travel(to entry: NavigationEntry) {}
    func forgetTimeline(domain: String) {}
}
