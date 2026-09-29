import Foundation
import Testing
@testable import RedentKit

@Suite("Navigation preferences")
struct NavigationSettingsTests {
    @Test("Older settings keep the top navigation bar and their other preferences")
    func upgradesWithoutChangingLayout() throws {
        let legacy = Data(#"{"tabLayout":"top","sidebarWidth":310,"blocksTrackers":false}"#.utf8)
        let settings = try JSONDecoder().decode(BrowserSettings.self, from: legacy)
        #expect(!settings.hidesNavigationBar)
        #expect(settings.tabLayout == .top)
        #expect(settings.sidebarWidth == 310)
        #expect(!settings.blocksTrackers)
    }

    @Test("Hiding navigation makes its sidebar available and survives saving")
    func hidingNavigationIsDurable() throws {
        var settings = BrowserSettings(tabLayout: .top, isTabStripVisible: false, sidebarWidth: 310)
        settings.setNavigationBarHidden(true)
        let restored = try JSONDecoder().decode(BrowserSettings.self, from: JSONEncoder().encode(settings))
        #expect(restored.hidesNavigationBar)
        #expect(restored.tabLayout == .sidebar)
        #expect(restored.isTabStripVisible)
        #expect(restored.sidebarWidth == 310)
        #expect(restored == settings)
    }

    @Test("Restoring navigation leaves the chosen tab layout and visibility alone")
    func restoringNavigationKeepsTabs() {
        var settings = BrowserSettings(tabLayout: .top, isTabStripVisible: false)
        settings.hidesNavigationBar = true
        settings.setNavigationBarHidden(false)
        #expect(!settings.hidesNavigationBar)
        #expect(settings.tabLayout == .top)
        #expect(!settings.isTabStripVisible)
    }
}
