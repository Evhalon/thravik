import Foundation
import Testing
@testable import RedentUI

@MainActor
@Suite("Address bar presentation")
struct AddressBarModelTests {
    private func url(_ raw: String) throws -> URL {
        try #require(URL(string: raw))
    }

    @Test("Schemes and www are hidden, the rest is kept")
    func prettyPrinting() throws {
        #expect(AddressBarModel.prettyPrint(try #require(URL(string: "https://www.example.com/"))) == "example.com")
        #expect(AddressBarModel.prettyPrint(try #require(URL(string: "https://example.com/a/b"))) == "example.com/a/b")
        #expect(AddressBarModel.prettyPrint(try #require(URL(string: "http://example.com"))) == "example.com")
    }

    @Test("Non-web URLs are shown verbatim")
    func nonWebURL() throws {
        let url = try #require(URL(string: "file:///Users/me/notes.txt"))
        #expect(AddressBarModel.prettyPrint(url) == url.absoluteString)
    }

    @Test("Committing resolves the typed text and ends editing")
    func commit() {
        let model = AddressBarModel()
        model.beginEditing(with: nil)
        model.text = "example.com"
        #expect(model.commit(using: .duckduckgo)?.absoluteString == "https://example.com")
        #expect(!model.isEditing)
    }

    @Test("Focused address exposes the complete URL for copying")
    func editingShowsCompleteURL() throws {
        let tab = InertTab()
        tab.url = try url("https://example.com/path?q=value#section")
        let model = AddressBarModel()

        model.sync(with: tab)
        model.beginEditing(with: tab)

        #expect(model.text == "https://example.com/path?q=value#section")
    }

    @Test("Changing tab replaces the address even while editing")
    func selectionChangeWhileEditing() throws {
        let first = InertTab()
        first.url = try url("https://first.example/path")
        let second = InertTab()
        second.url = try url("https://second.example/login")
        let model = AddressBarModel()
        model.beginEditing(with: first)

        model.syncSelection(with: second)

        #expect(model.text == "https://second.example/login")
    }

    @Test("Closing the last tab clears a stale address")
    func closingLastTab() throws {
        let tab = InertTab()
        tab.url = try url("https://tracker.example/redirect?token=value")
        let model = AddressBarModel()
        model.beginEditing(with: tab)

        model.sync(with: nil)

        #expect(model.text.isEmpty)
    }
}
