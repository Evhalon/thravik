import Foundation
import RedentKit
import Testing
@testable import RedentEngine

/// A tab with no address renders as the new-tab page, so losing one silently
/// turns a restored site into "home" while the sidebar still names the site.
@MainActor
@Suite("Tab address")
struct TabAddressTests {
    @Test("A failed first load does not erase a restored tab's address")
    func failedLoadKeepsAddress() throws {
        let url = try #require(URL(string: "https://crm.example/accounts"))
        let restored = TabSnapshot(url: url, title: "CRM")
        let controller = TabController(
            session: BrowserSession(tabs: [restored], selectedTabID: restored.id),
            settings: BrowserSettings(), logger: AddressLogger()
        )
        let tab = try #require(controller.selectedTab as? WebTab)

        tab.applyURL(nil)

        #expect(tab.url == url)
        #expect(tab.snapshot.url == url)
    }

    @Test("A tab saved without its address gets it back from its path")
    func restoresAddressFromTimeline() throws {
        let url = try #require(URL(string: "https://crm.example/accounts"))
        var broken = TabSnapshot(title: "CRM")
        broken.timeline.record(url: url, transition: .opened)
        let controller = TabController(
            session: BrowserSession(tabs: [broken], selectedTabID: broken.id),
            settings: BrowserSettings(), logger: AddressLogger()
        )

        #expect(controller.selectedTab?.url == url)
        #expect(controller.session.tabs.first?.url == url)
    }

    @Test("A genuine new tab stays blank")
    func newTabStaysBlank() {
        let blank = TabSnapshot()
        let controller = TabController(
            session: BrowserSession(tabs: [blank], selectedTabID: blank.id),
            settings: BrowserSettings(), logger: AddressLogger()
        )

        #expect(controller.selectedTab?.url == nil)
    }
}

private struct AddressLogger: EventLogging {
    func debug(_ message: @autoclosure () -> String) {}
    func notice(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}
