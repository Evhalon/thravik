import Foundation
import RedentKit
import Testing
@testable import RedentUI

@MainActor
@Suite("Tidy tabs window model")
struct TidyTabsModelTests {
    private func staleTab() -> TabSnapshot {
        var tab = TabSnapshot(title: "Stale", lastActiveAt: .now.addingTimeInterval(-3 * 24 * 3600))
        tab.spaceID = BrowserSpace.workID
        return tab
    }

    private func browser(staleCount: Int) -> FakeBrowser {
        let browser = FakeBrowser()
        var selected = TabSnapshot(title: "Current")
        selected.spaceID = BrowserSpace.workID
        browser.selectedID = selected.id
        browser.session = BrowserSession(
            tabs: [selected] + (0..<staleCount).map { _ in staleTab() },
            selectedTabID: selected.id
        )
        return browser
    }

    @Test("Off never suggests, even with stale tabs")
    func offIsQuiet() {
        let model = makeTestBrowserModel(tabs: browser(staleCount: 6))
        model.refreshTidyTabs()
        #expect(!model.showTidyTabsSuggestion)
        #expect(model.tidyTabsCandidateIDs.isEmpty)
    }

    @Test("Tabs restored from an archive are not offered again straight away")
    func restoredTabsStayQuiet() {
        let fake = browser(staleCount: 5)
        let model = makeTestBrowserModel(tabs: fake)
        model.settings.tidyTabsThreshold = .oneDay
        #expect(model.showTidyTabsSuggestion)
        #expect(model.tidyTabsCandidateIDs.count == 5)

        // The fake ignores the group action, leaving the tabs loose exactly as
        // Restore or ⌘Z would.
        model.tidyUnusedTabs()
        #expect(!model.showTidyTabsSuggestion)

        fake.session.tabs.append(staleTab())
        model.refreshTidyTabs()
        #expect(model.showTidyTabsSuggestion)
    }
}
