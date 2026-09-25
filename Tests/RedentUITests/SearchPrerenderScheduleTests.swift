import Foundation
import RedentKit
import Testing
@testable import RedentUI

@Suite("Search prerender schedule")
@MainActor
struct SearchPrerenderScheduleTests {
    @Test("A pause in typing a search loads its results page once")
    func pauseLoadsSearch() async throws {
        let browser = FakeBrowser()
        let model = makeTestBrowserModel(tabs: browser)
        model.queryChanged("swift", from: .addressBar)
        model.queryChanged("swift actors", from: .addressBar)
        for _ in 0..<200 where browser.prerendered.isEmpty {
            try await Task.sleep(for: .milliseconds(20))
        }

        let expected = model.settings.searchEngine.searchURL(for: "swift actors")
        #expect(browser.prerendered == [expected])
    }

    @Test("An address is never loaded ahead of return")
    func addressDropsPrerender() async throws {
        let browser = FakeBrowser()
        let model = makeTestBrowserModel(tabs: browser)
        model.queryChanged("example.com", from: .addressBar)
        try await Task.sleep(for: SearchPrerenderSchedule.pause * 3)

        #expect(browser.prerendered == [nil])
    }
}
