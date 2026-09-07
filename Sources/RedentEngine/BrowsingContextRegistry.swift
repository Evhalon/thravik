import RedentKit
import WebKit

/// Resolves a `BrowsingContext` to the one `WKWebsiteDataStore` that serves it.
///
/// The registry is the only place a store is created. Persistent Containers
/// keep their store for the life of the app so a reopened tab still finds its
/// cookies; an ephemeral store is dropped as soon as no tab references it,
/// which is what makes a temporary session actually disappear.
@MainActor
final class BrowsingContextRegistry {
    /// `private(set)` rather than `private`: the website-data face lives in a
    /// sibling file to stay under the line limit, and has to read it.
    private(set) var loadedStores: [BrowsingContext: WKWebsiteDataStore] = [:]
    private var tabCounts: [BrowsingContext: Int] = [:]

    func store(for context: BrowsingContext) -> WKWebsiteDataStore {
        if let existing = loadedStores[context] { return existing }
        let store = Self.makeStore(for: context)
        loadedStores[context] = store
        return store
    }

    /// Re-counts every live tab in one pass. Called after any tab mutation, so
    /// the registry cannot drift out of step with the tab list the way paired
    /// retain/release calls would.
    func sync(_ contexts: [BrowsingContext]) {
        var counts: [BrowsingContext: Int] = [:]
        for context in contexts { counts[context, default: 0] += 1 }
        for context in loadedStores.keys where counts[context] == nil && context.isEphemeral {
            loadedStores[context] = nil
        }
        tabCounts = counts
    }

    func tabCount(for context: BrowsingContext) -> Int { tabCounts[context] ?? 0 }

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
