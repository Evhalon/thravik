import RedentKit
import WebKit

/// The registry's website-data face. Deletion is scoped by WebKit's own record
/// attribution: Redent asks for the records, compares display names for
/// equality, and removes only those — never a substring match, which would
/// silently take `evil-example.com` down with `example.com`.
extension BrowsingContextRegistry: SiteDataManaging {
    public var loadedContexts: [BrowsingContext] { Array(loadedStores.keys) }

    public func records(in context: BrowsingContext) async -> [SiteDataRecord] {
        guard let store = loadedStores[context] else { return [] }
        let found = await store.dataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes())
        return found.map { SiteDataRecord(displayName: $0.displayName, dataTypes: $0.dataTypes) }
    }

    @discardableResult
    public func removeRecords(matching domain: String, in context: BrowsingContext) async -> [String] {
        guard let store = loadedStores[context] else { return [] }
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        let matches = await store.dataRecords(ofTypes: types)
            .filter { $0.displayName.caseInsensitiveCompare(domain) == .orderedSame }
        guard !matches.isEmpty else { return [] }
        await store.removeData(ofTypes: types, for: matches)
        return matches.map(\.displayName)
    }
}
