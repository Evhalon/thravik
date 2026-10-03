import Foundation
import Testing
@testable import RedentKit

@Suite("Custom search settings persistence")
struct CustomSearchSettingsTests {
    @Test("Older settings JSON without custom engines still decodes")
    func decodesLegacyJSON() throws {
        let legacy = Data(#"{"tabLayout":"top","searchEngine":"google","homepage":"https://www.google.com"}"#.utf8)
        let settings = try JSONDecoder().decode(BrowserSettings.self, from: legacy)
        #expect(settings.searchEngine == .google)
        #expect(settings.homepage == "https://www.google.com")
        #expect(settings.customSearchEngines.isEmpty)
        #expect(settings.activeCustomSearchEngineID == nil)
        #expect(settings.searchSelection == .builtIn(.google))
    }

    @Test("Custom engines and the chosen default survive a save")
    func roundTripsCustomEngines() throws {
        var settings = BrowserSettings()
        let youtube = try CustomSearchEngine.make(
            name: "YouTube",
            keyword: "yt",
            template: "https://www.youtube.com/results?search_query=%s",
            existing: []
        ).get()
        settings.addCustomSearchEngine(youtube)
        settings.select(.custom(youtube.id))
        #expect(settings.searchSelection == .custom(youtube.id))
        #expect(settings.searchRouting.label == "YouTube")

        let restored = try JSONDecoder().decode(BrowserSettings.self, from: JSONEncoder().encode(settings))
        #expect(restored.customSearchEngines == [youtube])
        #expect(restored.activeCustomSearchEngineID == youtube.id)
        #expect(restored.searchRouting.searchURL(for: "cats")?.host() == "www.youtube.com")
    }

    @Test("Removing the active custom engine falls back to the built-in")
    func removingActiveClearsSelection() throws {
        var settings = BrowserSettings()
        let engine = try CustomSearchEngine.make(
            name: "YouTube", keyword: "yt",
            template: "https://www.youtube.com/results?search_query=%s", existing: []
        ).get()
        settings.addCustomSearchEngine(engine)
        settings.select(.custom(engine.id))
        settings.removeCustomSearchEngine(id: engine.id)
        #expect(settings.customSearchEngines.isEmpty)
        #expect(settings.searchSelection == .builtIn(.duckduckgo))
        #expect(settings.homepage == SearchEngine.duckduckgo.homepage)
        #expect(settings.searchRouting.searchURL(for: "cats")?.host() == "duckduckgo.com")
    }

    @Test("A saved active engine whose template no longer validates searches the built-in")
    func invalidActiveTemplateFallsBack() {
        let broken = CustomSearchEngine(name: "Broken", keyword: "b", template: "javascript:alert(%s)")
        let routing = SearchRouting(engine: .google, customEngines: [broken], activeCustomID: broken.id)
        #expect(routing.searchURL(for: "cats")?.host() == "www.google.com")
        #expect(routing.label == "Google")
        #expect(AddressResolver.resolve("b cats", using: routing)?.host() == "www.google.com")
    }
}
