import Foundation
import RedentKit
import Testing
@testable import RedentUI

@Suite("Paste and Go command row")
struct PasteCommandRowTests {
    private func pasteRows(_ paste: PasteAndGoDecision.Action?) -> [CommandBarResult] {
        var context = CommandBarContext()
        context.clipboardPaste = paste
        return PageCommandDescriptors.all
            .filter { $0.matches("paste") }
            .compactMap { $0.row(in: context, query: "paste") }
    }

    @Test("Title follows what the clipboard holds")
    func titleFollowsClipboard() throws {
        let site = try #require(URL(string: "https://example.com"))
        let search = try #require(SearchEngine.google.searchURL(for: "cats"))
        #expect(pasteRows(.go(site)).map(\.title) == ["Paste and Go"])
        #expect(pasteRows(.search(search)).map(\.title) == ["Paste and Search"])
        #expect(pasteRows(.go(site)).first?.action == .pasteAndGo)
    }

    @Test("An empty clipboard offers no paste row")
    func emptyClipboardHidesRow() {
        #expect(pasteRows(nil).isEmpty)
    }
}
