import Foundation
import Testing
@testable import RedentKit

@Suite("Bookmarks bar settings")
struct BookmarksBarSettingsTests {
    @Test("Older settings JSON without the key leaves the bar hidden")
    func legacyJSONDefaultsOff() throws {
        let legacy = Data(#"{"tabLayout":"top","sidebarWidth":310,"blocksTrackers":false}"#.utf8)
        let settings = try JSONDecoder().decode(BrowserSettings.self, from: legacy)
        #expect(!settings.showsBookmarksBar)
        #expect(settings.tabLayout == .top)
        #expect(settings.sidebarWidth == 310)
    }

    @Test("A fresh profile keeps the bar hidden until the user opts in")
    func defaultIsHidden() {
        #expect(!BrowserSettings().showsBookmarksBar)
    }

    @Test("Turning the bar on survives a save")
    func persistsWhenEnabled() throws {
        var settings = BrowserSettings()
        settings.showsBookmarksBar = true
        let restored = try JSONDecoder().decode(BrowserSettings.self, from: JSONEncoder().encode(settings))
        #expect(restored.showsBookmarksBar)
        #expect(restored == settings)
    }
}
