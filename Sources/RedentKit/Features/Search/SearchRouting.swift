import Foundation

/// Built-in default engine plus any user-defined engines, including which one
/// a bare query should search.
public struct SearchRouting: Sendable, Equatable {
    public var engine: SearchEngine
    public var customEngines: [CustomSearchEngine]
    public var activeCustomID: UUID?

    public init(
        engine: SearchEngine,
        customEngines: [CustomSearchEngine] = [],
        activeCustomID: UUID? = nil
    ) {
        self.engine = engine
        self.customEngines = customEngines
        self.activeCustomID = activeCustomID
    }

    public var label: String {
        activeCustom?.name ?? engine.label
    }

    public var activeCustom: CustomSearchEngine? {
        guard let activeCustomID else { return nil }
        return customEngines.first { $0.id == activeCustomID && $0.searchURL(for: "x") != nil }
    }

    /// A custom template that no longer validates searches the built-in
    /// engine rather than leaving the query with nowhere to go.
    public func searchURL(for query: String) -> URL? {
        activeCustom?.searchURL(for: query) ?? engine.searchURL(for: query)
    }
}
