import Foundation

extension BrowserSettings {
    public var searchRouting: SearchRouting {
        SearchRouting(
            engine: searchEngine,
            customEngines: customSearchEngines,
            activeCustomID: activeCustomSearchEngineID
        )
    }

    public var searchSelection: SearchEngineSelection {
        if let id = activeCustomSearchEngineID, customSearchEngines.contains(where: { $0.id == id }) {
            return .custom(id)
        }
        return .builtIn(searchEngine)
    }

    public mutating func select(_ selection: SearchEngineSelection) {
        switch selection {
        case .builtIn(let engine): selectSearchEngine(engine)
        case .custom(let id): selectCustomSearchEngine(id)
        }
    }

    /// Picking an engine moves the homepage with it, so the two do not disagree.
    /// A homepage the user typed themselves is left alone.
    public mutating func selectSearchEngine(_ engine: SearchEngine) {
        activeCustomSearchEngineID = nil
        applyHomepageIfFollowing(engine.homepage)
        searchEngine = engine
    }

    public mutating func addCustomSearchEngine(_ engine: CustomSearchEngine) {
        customSearchEngines.append(engine)
    }

    /// Removing the active engine falls back to the built-in one, homepage too.
    public mutating func removeCustomSearchEngine(id: UUID) {
        if activeCustomSearchEngineID == id { selectSearchEngine(searchEngine) }
        customSearchEngines.removeAll { $0.id == id }
    }

    private mutating func selectCustomSearchEngine(_ id: UUID) {
        guard let engine = customSearchEngines.first(where: { $0.id == id }) else { return }
        activeCustomSearchEngineID = id
        if let page = engine.homepage { applyHomepageIfFollowing(page) }
    }

    private mutating func applyHomepageIfFollowing(_ page: String) {
        let trimmed = homepage.trimmingCharacters(in: .whitespacesAndNewlines)
        let followsEngine = trimmed.isEmpty
            || SearchEngine.allCases.contains { $0.homepage == trimmed }
            || customSearchEngines.contains { $0.homepage == trimmed }
        if followsEngine { homepage = page }
    }
}
