import Foundation
import Testing
@testable import RedentUI

@MainActor
@Suite("Address bar presentation")
struct AddressBarModelTests {
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
        model.beginEditing()
        model.text = "example.com"
        #expect(model.commit(using: .duckduckgo)?.absoluteString == "https://example.com")
        #expect(!model.isEditing)
    }
}
