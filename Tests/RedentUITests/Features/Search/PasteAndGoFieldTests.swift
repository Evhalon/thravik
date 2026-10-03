import AppKit
import Testing
import RedentKit
@testable import RedentUI

@MainActor
struct PasteAndGoFieldTests {
    @Test func floatingPasteOpensANewTabAndClosesThePanel() {
        let browser = FakeBrowser()
        let model = makeTestBrowserModel(tabs: browser)
        model.showsFloatingNewTab = true
        model.beginPasteAndGoEditing(.floatingNewTab)
        withClipboard("https://example.com") { model.pasteAndGo() }
        #expect(browser.openedURLs.map(\.?.absoluteString) == ["https://example.com"])
        #expect(!model.showsFloatingNewTab)
        #expect(model.pasteAndGoField == nil)
    }

    @Test func homePasteNavigatesTheCurrentTab() {
        let tab = InertTab()
        let browser = browser(selecting: tab)
        let model = makeTestBrowserModel(tabs: browser)
        model.beginPasteAndGoEditing(.newTabPage)
        withClipboard("example.com") { model.pasteAndGo() }
        #expect(tab.loadedURLs.map(\.absoluteString) == ["https://example.com"])
        #expect(browser.openedURLs.isEmpty)
        #expect(model.pasteAndGoField == .newTabPage)
    }

    @Test func addressPasteNavigatesTheCurrentTab() {
        let tab = InertTab()
        let browser = browser(selecting: tab)
        let model = makeTestBrowserModel(tabs: browser)
        model.beginPasteAndGoEditing(.address)
        withClipboard("https://example.com/docs") { model.pasteAndGo() }
        #expect(tab.loadedURLs.map(\.absoluteString) == ["https://example.com/docs"])
        #expect(browser.openedURLs.isEmpty)
    }

    @Test func blurOfAnotherFieldDoesNotDisarmTheFocusedOne() {
        let model = makeTestBrowserModel()
        model.beginPasteAndGoEditing(.newTabPage)
        model.endPasteAndGoEditing(.floatingNewTab)
        #expect(model.pasteAndGoField == .newTabPage)
        model.endPasteAndGoEditing(.newTabPage)
        #expect(model.pasteAndGoField == nil)
    }

    private func browser(selecting tab: InertTab) -> FakeBrowser {
        let browser = FakeBrowser()
        browser.stubTabs = [tab]
        browser.selectedID = tab.id
        return browser
    }

    private func withClipboard(_ text: String, _ body: () -> Void) {
        let board = NSPasteboard.general
        let previous = board.string(forType: .string)
        board.clearContents()
        board.setString(text, forType: .string)
        defer {
            board.clearContents()
            if let previous { board.setString(previous, forType: .string) }
        }
        body()
    }
}
