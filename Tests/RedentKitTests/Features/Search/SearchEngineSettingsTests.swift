import Testing
@testable import RedentKit

@Suite struct SearchEngineSettingsTests {
    @Test func homepageFollowsTheEngineWhenItWasNeverCustomised() {
        var settings = BrowserSettings()
        settings.selectSearchEngine(.google)
        #expect(settings.searchEngine == .google)
        #expect(settings.homepage == SearchEngine.google.homepage)
    }

    @Test func aChosenHomepageSurvivesAnEngineChange() {
        var settings = BrowserSettings(homepage: "https://news.ycombinator.com")
        settings.selectSearchEngine(.bing)
        #expect(settings.homepage == "https://news.ycombinator.com")
    }

    @Test func anEmptyHomepageIsFilledIn() {
        var settings = BrowserSettings(homepage: "  ")
        settings.selectSearchEngine(.ecosia)
        #expect(settings.homepage == SearchEngine.ecosia.homepage)
    }

    @Test func everyEngineHomepageIsDistinct() {
        let homepages = Set(SearchEngine.allCases.map(\.homepage))
        #expect(homepages.count == SearchEngine.allCases.count)
    }
}
