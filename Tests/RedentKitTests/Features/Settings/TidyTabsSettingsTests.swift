import Foundation
import Testing
@testable import RedentKit

@Suite("Tidy tabs settings")
struct TidyTabsSettingsTests {
    @Test("Legacy settings decode as off")
    func legacyDecode() throws {
        let legacy = Data("""
        {"tabLayout":"sidebar","isTabStripVisible":true,"sidebarWidth":248,"hibernation":"balanced","homepage":"https://example.com","reopensTabsOnLaunch":true}
        """.utf8)
        let settings = try JSONDecoder().decode(BrowserSettings.self, from: legacy)
        #expect(settings.tidyTabsThreshold == .off)
    }

    @Test("Threshold round-trips through JSON")
    func roundTrip() throws {
        var settings = BrowserSettings()
        settings.tidyTabsThreshold = .threeDays
        let restored = try JSONDecoder().decode(BrowserSettings.self, from: JSONEncoder().encode(settings))
        #expect(restored.tidyTabsThreshold == .threeDays)
    }
}
