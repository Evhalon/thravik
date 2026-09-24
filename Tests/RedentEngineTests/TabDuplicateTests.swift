import Foundation
import RedentKit
import Testing
@testable import RedentEngine

@Suite("Duplicating tabs")
@MainActor
struct TabDuplicateTests {
    private func controller() -> TabController {
        TabController(session: BrowserSession(), settings: BrowserSettings(), logger: DuplicateLogger())
    }

    @Test("The copy opens the same page right after its source and takes the selection")
    func copySitsBesideSource() throws {
        let browser = controller()
        let url = try #require(URL(string: "https://example.com/a"))
        let source = browser.newTab(url: url)
        browser.newTab(url: URL(string: "https://example.org"))
        let copy = try #require(browser.duplicateTab(source.id))
        let ids = browser.tabs.map(\.id)
        let sourceIndex = try #require(ids.firstIndex(of: source.id))
        #expect(ids[sourceIndex + 1] == copy.id)
        #expect(copy.id != source.id)
        #expect(copy.snapshot.url == url)
        #expect(browser.selectedID == copy.id)
    }

    @Test("The copy keeps its source's Space and group")
    func copyKeepsPlacement() throws {
        let browser = controller()
        let source = browser.newTab(url: URL(string: "https://example.com"))
        let copy = try #require(browser.duplicateTab(source.id))
        #expect(copy.snapshot.spaceID == source.snapshot.spaceID)
        #expect(copy.snapshot.groupID == source.snapshot.groupID)
        #expect(copy.snapshot.containerID == source.snapshot.containerID)
    }

    @Test("An unknown tab duplicates to nothing")
    func unknownTab() {
        #expect(controller().duplicateTab(UUID()) == nil)
    }
}

private struct DuplicateLogger: EventLogging {
    func debug(_ message: @autoclosure () -> String) {}
    func notice(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}
