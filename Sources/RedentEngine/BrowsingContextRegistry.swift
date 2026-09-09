import RedentKit
import WebKit

/// Resolves a `BrowsingContext` to the one `WKWebsiteDataStore` that serves it.
///
/// The registry is the only place a store is created, and there is exactly one
/// registry for the process: two windows browsing the same Container must share
/// its cookies, and two `WKWebsiteDataStore`s for one identifier would not.
/// Persistent Containers keep their store for the life of the app so a reopened
/// tab still finds its cookies; an ephemeral store is dropped as soon as no tab
/// in any window references it, which is what makes a private session actually
/// disappear.
@MainActor
public final class BrowsingContextRegistry {
    /// `private(set)` rather than `private`: the website-data face lives in a
    /// sibling file to stay under the line limit, and has to read it.
    private(set) var loadedStores: [BrowsingContext: WKWebsiteDataStore] = [:]
    /// Counts are kept per owning controller, so one window re-counting its own
    /// tabs cannot report another window's tabs as gone.
    private var tabCounts: [ObjectIdentifier: [BrowsingContext: Int]] = [:]

    public init() {}

    func store(for context: BrowsingContext) -> WKWebsiteDataStore {
        if let existing = loadedStores[context] { return existing }
        let store = Self.makeStore(for: context)
        loadedStores[context] = store
        return store
    }

    /// Re-counts one owner's live tabs in a single pass. Called after any tab
    /// mutation, so the registry cannot drift out of step with the tab list the
    /// way paired retain/release calls would.
    func sync(_ contexts: [BrowsingContext], owner: ObjectIdentifier) {
        var counts: [BrowsingContext: Int] = [:]
        for context in contexts { counts[context, default: 0] += 1 }
        tabCounts[owner] = counts
        dropUnreferencedEphemeralStores()
    }

    /// A window closed. Its ephemeral stores go with it, unless another window
    /// is still browsing in them.
    func release(owner: ObjectIdentifier) {
        tabCounts[owner] = nil
        dropUnreferencedEphemeralStores()
    }

    func tabCount(for context: BrowsingContext) -> Int {
        tabCounts.values.reduce(0) { $0 + ($1[context] ?? 0) }
    }

    func isLoaded(_ context: BrowsingContext) -> Bool { loadedStores[context] != nil }

    /// Erases everything a context has stored, leaving the store itself usable.
    func removeData(for context: BrowsingContext) async {
        guard let store = loadedStores[context] else { return }
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        let records = await store.dataRecords(ofTypes: types)
        await store.removeData(ofTypes: types, for: records)
    }

    /// Retires a Container's profile from disk. Fails while tabs still use it,
    /// rather than silently dropping a store out from under a live view.
    func removeStore(for context: BrowsingContext) async throws {
        guard tabCount(for: context) == 0 else { throw BrowsingContextError.inUse }
        guard let id = context.containerID, id != BrowserContainer.defaultID else {
            throw BrowsingContextError.notRemovable
        }
        loadedStores[context] = nil
        try await WKWebsiteDataStore.remove(forIdentifier: id)
    }

    private func dropUnreferencedEphemeralStores() {
        for context in loadedStores.keys where context.isEphemeral && tabCount(for: context) == 0 {
            loadedStores[context] = nil
        }
    }

    private static func makeStore(for context: BrowsingContext) -> WKWebsiteDataStore {
        switch context {
        case .ephemeral:
            return .nonPersistent()
        case let .container(id):
            // `.default()` partitions cookies by code-directory hash. Ad-hoc
            // rebuilds then look like a brand-new browser. A UUID store does not.
            return WKWebsiteDataStore(forIdentifier: id)
        }
    }
}

public enum BrowsingContextError: Error, Equatable {
    case inUse
    case notRemovable
}
