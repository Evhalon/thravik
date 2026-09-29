import Foundation
import RedentKit
import Testing
import WebKit
@testable import RedentEngine

@Suite("Related child tabs")
@MainActor
struct RelatedChildTabTests {
    private func controller() -> TabController {
        TabController(session: BrowserSession(), settings: BrowserSettings(), logger: QuietLogger())
    }

    @Test("Opening a popup groups it with the opener in the sidebar")
    func popupCreatesRelatedGroup() throws {
        let browser = controller()
        let parentURL = try #require(URL(string: "https://example.com/mifid"))
        let childURL = try #require(URL(string: "https://example.com/ticket"))
        let parent = try #require(browser.newTab(url: parentURL) as? WebTab)
        parent.snapshot.title = "MiFID Correttiva"
        let child = browser.openPopupTab(
            configuration: WKWebViewConfiguration(), url: childURL, of: parent.snapshot
        )
        #expect(child.snapshot.parentTabID == parent.id)
        #expect(child.snapshot.groupID != nil)
        #expect(parent.snapshot.groupID == child.snapshot.groupID)
        #expect(browser.session.groups.contains { $0.name == "MiFID Correttiva" })
        let outline = SidebarOutline(
            tabs: browser.session.tabs,
            groups: browser.session.groups,
            spaceID: browser.session.selectedSpaceID
        )
        guard case let .cluster(cluster) = outline.nodes.last else {
            Issue.record("expected related cluster")
            return
        }
        #expect(cluster.headerTabID == parent.id)
        #expect(cluster.memberIDs == [child.id])
    }

    @Test("A second popup joins the same related group")
    func secondPopupJoins() throws {
        let browser = controller()
        let parent = try #require(browser.newTab(url: URL(string: "https://example.com")) as? WebTab)
        parent.snapshot.title = "Parent"
        let firstURL = try #require(URL(string: "https://example.com/a"))
        browser.openPopupTab(
            configuration: WKWebViewConfiguration(), url: firstURL, of: parent.snapshot
        )
        let liveParent = try #require(browser.webTabs.first)
        let secondURL = try #require(URL(string: "https://example.com/b"))
        browser.openPopupTab(
            configuration: WKWebViewConfiguration(), url: secondURL, of: liveParent.snapshot
        )
        #expect(browser.session.groups.count == 1)
        #expect(browser.session.groups[0].tabIDs.count == 3)
        let outline = SidebarOutline(
            tabs: browser.session.tabs,
            groups: browser.session.groups,
            spaceID: browser.session.selectedSpaceID
        )
        guard case let .cluster(cluster) = outline.nodes.last else {
            Issue.record("expected related cluster")
            return
        }
        #expect(cluster.headerTabID == parent.id)
        #expect(cluster.memberIDs.count == 2)
    }

    @Test("Closing the opener leaves children as ordinary tabs")
    func closeParentDetachesChildren() throws {
        let browser = controller()
        let parent = try #require(browser.newTab(url: URL(string: "https://example.com")) as? WebTab)
        parent.snapshot.title = "Parent"
        let childURL = try #require(URL(string: "https://example.com/a"))
        let child = browser.openPopupTab(
            configuration: WKWebViewConfiguration(), url: childURL, of: parent.snapshot
        )
        browser.close(parent.id)
        #expect(child.snapshot.parentTabID == nil)
    }

    @Test("A popup closing itself removes its child tab")
    func scriptClosedPopupDisappears() throws {
        let browser = controller()
        let parent = try #require(browser.newTab(url: URL(string: "https://example.com")) as? WebTab)
        let child = browser.openPopupTab(
            configuration: WKWebViewConfiguration(),
            url: URL(string: "https://login.example.com"), of: parent.snapshot
        )
        let view = try #require(child.webView)
        child.navigationDelegate?.webViewDidClose(view)
        #expect(browser.webTabs.map(\.id) == [parent.id])
        #expect(browser.session.groups.isEmpty)
    }
}

private struct QuietLogger: EventLogging {
    func debug(_ message: @autoclosure () -> String) {}
    func notice(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}
